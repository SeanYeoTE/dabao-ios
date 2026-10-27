import MapKit
import UIKit

/// Top of the tracking screen: the delivery map, restaurant tile, name, a large ETA, the arrival time and the stage timeline.
final class OrderTrackingHeaderView: UIView {

    private let tile = SymbolTileView(side: 72)
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textSecondary)
    private let etaLabel = UILabel.ds(font: DS.Font.largeTitle, color: DS.Color.textPrimary)
    private let arrivalLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let riderLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textPrimary)
    private let mapView = DeliveryMapView()
    private var shownMap: OrderTrackingMapViewModel?
    private var shownRider: OrderTrackingRiderViewModel?
    private let timeline = DeliveryTimelineView()
    private let hero = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        for label in [nameLabel, etaLabel, arrivalLabel, riderLabel] {
            label.textAlignment = .center
        }
        for view in [tile, nameLabel, etaLabel, arrivalLabel, riderLabel] {
            hero.addArrangedSubview(view)
        }
        hero.axis = .vertical
        hero.alignment = .center
        hero.spacing = DS.Spacing.xs
        hero.setCustomSpacing(DS.Spacing.m, after: tile)
        hero.setCustomSpacing(DS.Spacing.s, after: etaLabel)
        for label in [nameLabel, etaLabel, arrivalLabel, riderLabel] {
            label.widthAnchor.constraint(lessThanOrEqualTo: hero.widthAnchor).isActive = true
        }

        let root = UIStackView(arrangedSubviews: [mapView, hero, timeline])
        root.axis = .vertical
        root.alignment = .fill
        root.spacing = DS.Spacing.xl
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        root.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.l, left: DS.Spacing.l, bottom: DS.Spacing.l, right: DS.Spacing.l))

        hero.isAccessibilityElement = true
        hero.accessibilityTraits = .header
    }

    func configure(_ header: OrderTrackingHeaderViewModel) {
        tile.configure(symbolName: header.symbolName, tint: UIColor(hex: header.colorHex))
        nameLabel.text = header.restaurantName
        etaLabel.text = header.etaText
        etaLabel.textColor = header.isDelivered ? DS.Color.success : DS.Color.textPrimary
        arrivalLabel.text = header.arrivalText
        riderLabel.text = header.riderModel.distanceText
        hero.accessibilityLabel = "\(header.restaurantName), \(header.etaText), \(header.arrivalText), \(header.riderModel.distanceText)"
        configureMap(header.mapModel, rider: header.riderModel)
    }

    // The map is only configured when its markers or route change, so panning and zooming survive each tracker tick.
    private func configureMap(_ map: OrderTrackingMapViewModel, rider: OrderTrackingRiderViewModel) {
        let isFirstShow = shownMap == nil
        if map != shownMap {
            shownMap = map
            mapView.configure(restaurant: map.restaurant.coordinate,
                              restaurantSymbol: map.symbolName,
                              restaurantTint: UIColor(hex: map.colorHex),
                              home: map.home.coordinate,
                              route: map.route.map(\.coordinate),
                              isApproximateRoute: map.isApproximateRoute)
            shownRider = nil
        }
        if rider != shownRider {
            let previous = shownRider
            shownRider = rider
            if rider.coordinate != previous?.coordinate {
                mapView.setRider(rider.coordinate?.coordinate, animated: !isFirstShow && window != nil)
            }
            if rider.isWaitingAtRestaurant != previous?.isWaitingAtRestaurant {
                mapView.setWaitingAtRestaurant(rider.isWaitingAtRestaurant)
            }
            mapView.accessibilitySummary = rider.accessibilitySummary
        }
    }

    func configureTimeline(_ model: OrderTrackingTimelineViewModel, animated: Bool) {
        timeline.configure(stages: model.stages, currentIndex: model.currentIndex, animated: animated)
    }
}

private extension GeoPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
