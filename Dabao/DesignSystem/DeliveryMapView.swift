import MapKit
import UIKit

/// A muted map showing the restaurant, the home pin, the route and (optionally) the rider.
/// Takes plain values only. VoiceOver sees one element labelled with `accessibilitySummary`.
final class DeliveryMapView: UIView {

    static let standardHeight: CGFloat = 240
    static let accessibilityHeight: CGFloat = 200

    /// Symbol used for the rider marker ("bicycle" or "scooter").
    var riderSymbol: String = "bicycle" {
        didSet { (mapView.view(for: riderAnnotation) as? RiderAnnotationView)?.configure(symbolName: riderSymbol) }
    }

    var accessibilitySummary: String {
        get { accessibilityLabel ?? "" }
        set { accessibilityLabel = newValue }
    }

    private let mapView = MKMapView()
    private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: Self.standardHeight)

    private let restaurantAnnotation = MarkerAnnotation(kind: .restaurant)
    private let homeAnnotation = MarkerAnnotation(kind: .home)
    private let riderAnnotation = MarkerAnnotation(kind: .rider)
    private var riderOnMap = false

    private var restaurantSymbol = "fork.knife"
    private var restaurantTint: UIColor = DS.Color.brand
    private var isWaiting = false
    private var polyline: MKPolyline?
    private var isApproximate = false
    private var pendingFit: MKMapRect?
    private var lastFit: MKMapRect?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DS.Color.surface
        layer.cornerRadius = DS.Radius.card
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        let configuration = MKStandardMapConfiguration(emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = configuration
        mapView.pointOfInterestFilter = .excludingAll
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = false
        mapView.showsUserLocation = false
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.register(RestaurantAnnotationView.self, forAnnotationViewWithReuseIdentifier: RestaurantAnnotationView.reuseID)
        mapView.register(RiderAnnotationView.self, forAnnotationViewWithReuseIdentifier: RiderAnnotationView.reuseID)
        mapView.register(HomeAnnotationView.self, forAnnotationViewWithReuseIdentifier: HomeAnnotationView.reuseID)
        addSubview(mapView)

        heightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint
        ])

        isAccessibilityElement = true
        accessibilityTraits = .image
        updateHeight()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitUserInterfaceStyle.self]) { (view: DeliveryMapView, _) in
            view.updateHeight()
            view.refreshRouteColor()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(reduceMotionChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil
        )
        // Core Animation drops running animations when the app is backgrounded.
        NotificationCenter.default.addObserver(
            self, selector: #selector(reduceMotionChanged),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Public API

    func configure(
        restaurant: CLLocationCoordinate2D, restaurantSymbol: String, restaurantTint: UIColor,
        home: CLLocationCoordinate2D, route: [CLLocationCoordinate2D], isApproximateRoute: Bool
    ) {
        self.restaurantSymbol = restaurantSymbol
        self.restaurantTint = restaurantTint
        isApproximate = isApproximateRoute

        restaurantAnnotation.coordinate = restaurant
        homeAnnotation.coordinate = home
        if restaurantAnnotation.isOnMap == false {
            restaurantAnnotation.isOnMap = true
            homeAnnotation.isOnMap = true
            mapView.addAnnotations([homeAnnotation, restaurantAnnotation])
        }
        (mapView.view(for: restaurantAnnotation) as? RestaurantAnnotationView)?
            .configure(symbolName: restaurantSymbol, tint: restaurantTint)

        if let polyline { mapView.removeOverlay(polyline) }
        polyline = nil
        let points = route.filter { CLLocationCoordinate2DIsValid($0) }
        if points.count >= 2 {
            let line = MKPolyline(coordinates: points, count: points.count)
            polyline = line
            mapView.addOverlay(line, level: .aboveRoads)
        }

        var rect = MKMapRect.null
        for coordinate in [restaurant, home] + points where CLLocationCoordinate2DIsValid(coordinate) {
            let point = MKMapPoint(coordinate)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        guard !rect.isNull else { return }
        if lastFit.map({ !MKMapRectEqualToRect($0, rect) }) ?? true {
            lastFit = rect
            pendingFit = rect
            applyPendingFit()
        }
    }

    func setRider(_ coordinate: CLLocationCoordinate2D?, animated: Bool) {
        guard let coordinate, CLLocationCoordinate2DIsValid(coordinate) else {
            if riderOnMap {
                riderOnMap = false
                mapView.removeAnnotation(riderAnnotation)
            }
            return
        }
        guard riderOnMap else {
            riderAnnotation.coordinate = coordinate
            riderOnMap = true
            mapView.addAnnotation(riderAnnotation)
            return
        }
        if animated, window != nil, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveLinear, .beginFromCurrentState, .allowUserInteraction]) {
                self.riderAnnotation.coordinate = coordinate
            }
        } else {
            riderAnnotation.coordinate = coordinate
        }
    }

    func setWaitingAtRestaurant(_ waiting: Bool) {
        isWaiting = waiting
        updatePulse()
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        applyPendingFit()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePulse()
    }

    private func updateHeight() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        heightConstraint.constant = isAccessibilitySize ? Self.accessibilityHeight : Self.standardHeight
    }

    private func applyPendingFit() {
        guard let rect = pendingFit, mapView.bounds.width > 0, mapView.bounds.height > 0 else { return }
        pendingFit = nil
        let padding = UIEdgeInsets(top: 56, left: 48, bottom: 40, right: 48)
        mapView.setVisibleMapRect(rect, edgePadding: padding, animated: false)
    }

    private func updatePulse() {
        (mapView.view(for: restaurantAnnotation) as? RestaurantAnnotationView)?.setPulsing(isWaiting)
    }

    @objc private func reduceMotionChanged() {
        updatePulse()
    }

    private func refreshRouteColor() {
        guard let polyline, let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer else { return }
        renderer.strokeColor = DS.Color.brand.resolvedColor(with: traitCollection)
        renderer.setNeedsDisplay()
    }
}

extension DeliveryMapView: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard let marker = annotation as? MarkerAnnotation else { return nil }
        let view: MKAnnotationView
        switch marker.kind {
        case .restaurant:
            let restaurant = mapView.dequeueReusableAnnotationView(
                withIdentifier: RestaurantAnnotationView.reuseID, for: annotation
            ) as? RestaurantAnnotationView
            restaurant?.configure(symbolName: restaurantSymbol, tint: restaurantTint)
            restaurant?.setPulsing(isWaiting)
            restaurant?.zPriority = MKAnnotationViewZPriority(rawValue: 500)
            view = restaurant ?? MKAnnotationView()
        case .rider:
            let rider = mapView.dequeueReusableAnnotationView(
                withIdentifier: RiderAnnotationView.reuseID, for: annotation
            ) as? RiderAnnotationView
            rider?.configure(symbolName: riderSymbol)
            rider?.zPriority = .max
            view = rider ?? MKAnnotationView()
        case .home:
            view = mapView.dequeueReusableAnnotationView(withIdentifier: HomeAnnotationView.reuseID, for: annotation)
            view.zPriority = .min
        }
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
        view.canShowCallout = false
        view.isEnabled = false
        return view
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: line)
        renderer.strokeColor = DS.Color.brand.resolvedColor(with: traitCollection)
        renderer.lineWidth = 5
        renderer.lineJoin = .round
        if isApproximate {
            renderer.lineCap = .butt
            renderer.lineDashPattern = [10, 8]
        } else {
            renderer.lineCap = .round
        }
        return renderer
    }
}

// MARK: - Annotations

/// `coordinate` is `@objc dynamic` so that changing it inside `UIView.animate` moves the marker smoothly.
private final class MarkerAnnotation: NSObject, MKAnnotation {

    enum Kind { case restaurant, rider, home }

    let kind: Kind
    var isOnMap = false
    @objc dynamic var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    init(kind: Kind) {
        self.kind = kind
    }
}

/// Shared look: a circle with a white ring and a soft shadow.
private class RingedAnnotationView: MKAnnotationView {

    let ringView = UIView()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        displayPriority = .required
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        ringView.isUserInteractionEnabled = false
        ringView.layer.shadowColor = UIColor.black.cgColor
        ringView.layer.shadowOpacity = 0.3
        ringView.layer.shadowRadius = 4
        ringView.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(ringView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Lays out the circle at `side` points and keeps the annotation view the same size.
    func install(side: CGFloat) {
        frame = CGRect(x: 0, y: 0, width: side, height: side)
        ringView.frame = bounds
        ringView.layer.cornerRadius = side / 2
        ringView.backgroundColor = .white
    }
}

private final class RestaurantAnnotationView: RingedAnnotationView {

    static let reuseID = "restaurant"
    private static let side: CGFloat = 46
    private static let pulseKey = "pulse"

    private let tile = SymbolTileView(side: 38)
    private let tileBackdrop = UIView()
    private let pulseView = UIView()
    private var isPulsing = false

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        install(side: Self.side)

        pulseView.isUserInteractionEnabled = false
        pulseView.frame = bounds
        pulseView.layer.cornerRadius = Self.side / 2
        pulseView.alpha = 0
        insertSubview(pulseView, belowSubview: ringView)

        tileBackdrop.frame = bounds.insetBy(dx: 4, dy: 4)
        tileBackdrop.layer.cornerRadius = tileBackdrop.bounds.height / 2
        tileBackdrop.layer.masksToBounds = true
        tileBackdrop.isUserInteractionEnabled = false
        ringView.addSubview(tileBackdrop)

        tile.translatesAutoresizingMaskIntoConstraints = true
        tile.frame = tileBackdrop.bounds
        tile.layer.cornerRadius = tile.bounds.height / 2
        tile.layer.cornerCurve = .circular
        tile.isUserInteractionEnabled = false
        tileBackdrop.addSubview(tile)
        // The tint is translucent, so the backdrop gives it a solid base on the map.
        tileBackdrop.backgroundColor = DS.Color.surfaceElevated
        ringView.backgroundColor = DS.Color.surfaceElevated
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(symbolName: String, tint: UIColor) {
        tile.configure(symbolName: symbolName, tint: tint)
        pulseView.backgroundColor = tint
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setPulsing(false)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if isPulsing { startPulse() }
    }

    func setPulsing(_ pulsing: Bool) {
        isPulsing = pulsing
        if pulsing { startPulse() } else { stopPulse() }
    }

    private func startPulse() {
        pulseView.layer.removeAnimation(forKey: Self.pulseKey)
        guard UIAccessibility.isReduceMotionEnabled else {
            pulseView.transform = .identity
            pulseView.alpha = 0.35
            guard window != nil else { return }
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.0
            scale.toValue = 1.9
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.45
            fade.toValue = 0.0
            let group = CAAnimationGroup()
            group.animations = [scale, fade]
            group.duration = 1.4
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            pulseView.layer.add(group, forKey: Self.pulseKey)
            return
        }
        // Reduce Motion: a static halo instead of the pulse.
        pulseView.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
        pulseView.alpha = 0.3
    }

    private func stopPulse() {
        pulseView.layer.removeAnimation(forKey: Self.pulseKey)
        pulseView.transform = .identity
        pulseView.alpha = 0
    }
}

private final class RiderAnnotationView: RingedAnnotationView {

    static let reuseID = "rider"
    private static let side: CGFloat = 40

    private let imageView = UIImageView()
    private let disc = UIView()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        install(side: Self.side)
        ringView.backgroundColor = .white

        disc.frame = bounds.insetBy(dx: 3, dy: 3)
        disc.layer.cornerRadius = disc.bounds.height / 2
        disc.isUserInteractionEnabled = false
        disc.backgroundColor = DS.Color.brand
        ringView.addSubview(disc)

        imageView.frame = disc.bounds
        imageView.contentMode = .center
        imageView.tintColor = DS.Color.onBrand
        disc.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(symbolName: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        imageView.image = UIImage(systemName: symbolName, withConfiguration: configuration)
            ?? UIImage(systemName: "bicycle", withConfiguration: configuration)
    }
}

private final class HomeAnnotationView: RingedAnnotationView {

    static let reuseID = "home"
    private static let side: CGFloat = 36

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        install(side: Self.side)
        ringView.backgroundColor = .white

        let disc = UIView(frame: bounds.insetBy(dx: 3, dy: 3))
        disc.layer.cornerRadius = disc.bounds.height / 2
        disc.isUserInteractionEnabled = false
        disc.backgroundColor = DS.Color.textPrimary
        ringView.addSubview(disc)

        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let imageView = UIImageView(image: UIImage(systemName: "house.fill", withConfiguration: configuration))
        imageView.frame = disc.bounds
        imageView.contentMode = .center
        // textPrimary flips between dark and light, so the glyph uses the opposite surface colour.
        imageView.tintColor = DS.Color.surface
        disc.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
