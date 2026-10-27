import Foundation

/// A plain latitude and longitude, so models and presenters never need MapKit.
nonisolated struct GeoPoint: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

/// The fixed places on the delivery map.
nonisolated enum DeliveryLocations {

    static let home = GeoPoint(latitude: 1.33310, longitude: 103.77640)
    static let homeName = "Home · Ngee Ann Polytechnic"

    private static let singaporeCentre = GeoPoint(latitude: 1.3000, longitude: 103.8500)
    private static let maxOffsetDegrees = 0.004

    /// Approximate neighbourhood centres, keyed by lowercase area name.
    private static let areaCentres: [String: GeoPoint] = [
        "ang mo kio": GeoPoint(latitude: 1.3691, longitude: 103.8454),
        "bedok": GeoPoint(latitude: 1.3236, longitude: 103.9273),
        "bishan": GeoPoint(latitude: 1.3508, longitude: 103.8485),
        "bugis": GeoPoint(latitude: 1.3009, longitude: 103.8559),
        "bukit timah": GeoPoint(latitude: 1.3294, longitude: 103.8021),
        "chinatown": GeoPoint(latitude: 1.2833, longitude: 103.8438),
        "clementi": GeoPoint(latitude: 1.3151, longitude: 103.7649),
        "geylang": GeoPoint(latitude: 1.3201, longitude: 103.8918),
        "holland village": GeoPoint(latitude: 1.3112, longitude: 103.7961),
        "hougang": GeoPoint(latitude: 1.3712, longitude: 103.8863),
        "joo chiat": GeoPoint(latitude: 1.3140, longitude: 103.9019),
        "jurong east": GeoPoint(latitude: 1.3329, longitude: 103.7436),
        "kallang": GeoPoint(latitude: 1.3114, longitude: 103.8714),
        "katong": GeoPoint(latitude: 1.3050, longitude: 103.9050),
        "lavender": GeoPoint(latitude: 1.3075, longitude: 103.8630),
        "little india": GeoPoint(latitude: 1.3066, longitude: 103.8518),
        "marine parade": GeoPoint(latitude: 1.3020, longitude: 103.9072),
        "novena": GeoPoint(latitude: 1.3204, longitude: 103.8438),
        "pasir ris": GeoPoint(latitude: 1.3721, longitude: 103.9474),
        "punggol": GeoPoint(latitude: 1.4043, longitude: 103.9021),
        "queenstown": GeoPoint(latitude: 1.2942, longitude: 103.8060),
        "redhill": GeoPoint(latitude: 1.2897, longitude: 103.8168),
        "sengkang": GeoPoint(latitude: 1.3868, longitude: 103.8914),
        "serangoon": GeoPoint(latitude: 1.3554, longitude: 103.8679),
        "tampines": GeoPoint(latitude: 1.3496, longitude: 103.9568),
        "telok ayer": GeoPoint(latitude: 1.2819, longitude: 103.8480),
        "tiong bahru": GeoPoint(latitude: 1.2866, longitude: 103.8327),
        "toa payoh": GeoPoint(latitude: 1.3343, longitude: 103.8563),
        "woodlands": GeoPoint(latitude: 1.4370, longitude: 103.7865),
        "yishun": GeoPoint(latitude: 1.4304, longitude: 103.8354),
    ]

    /// The restaurant's place on the map: its area's centre plus a small offset that is the same on every launch.
    static func coordinate(forArea area: String?, restaurantID: String) -> GeoPoint {
        let key = area?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let centre = areaCentres[key] ?? singaporeCentre
        let hash = stableHash(restaurantID)
        let latUnit = Double(hash & 0xFFFF) / 65535
        let lonUnit = Double((hash >> 16) & 0xFFFF) / 65535
        return GeoPoint(latitude: centre.latitude + (latUnit * 2 - 1) * maxOffsetDegrees,
                        longitude: centre.longitude + (lonUnit * 2 - 1) * maxOffsetDegrees)
    }

    /// FNV-1a over the UTF-8 bytes, mixed. Unlike `hashValue`, it never changes between launches.
    static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        // Finalise so the high bits differ too, even for ids that differ in one trailing character.
        hash ^= hash >> 33
        hash = hash &* 0xff51afd7ed558ccd
        hash ^= hash >> 33
        hash = hash &* 0xc4ceb9fe1a85ec53
        hash ^= hash >> 33
        return hash
    }
}

/// The path from the restaurant to the door.
nonisolated struct DeliveryRoute: Equatable, Sendable {
    /// At least 2 points: the restaurant first, home last.
    let points: [GeoPoint]
    let distanceMeters: Double
    /// True for the curved fallback, which isn't a real road route.
    let isApproximate: Bool

    /// The point `f` of the way along the route by distance. `f` is clamped to 0...1.
    func point(atFraction f: Double) -> GeoPoint {
        guard let first = points.first, let last = points.last else { return DeliveryLocations.home }
        let fraction = Self.clamp(f)
        if fraction <= 0 { return first }
        if fraction >= 1 { return last }

        let cumulative = cumulativeMeters()
        guard let total = cumulative.last, total > 0 else { return first }
        let target = total * fraction
        for index in 1..<points.count where cumulative[index] >= target {
            let segment = cumulative[index] - cumulative[index - 1]
            let t = segment > 0 ? (target - cumulative[index - 1]) / segment : 0
            let a = points[index - 1]
            let b = points[index]
            return GeoPoint(latitude: a.latitude + (b.latitude - a.latitude) * t,
                            longitude: a.longitude + (b.longitude - a.longitude) * t)
        }
        return last
    }

    /// How far the rider still has to go, `f` of the way along the route.
    func remainingMeters(atFraction f: Double) -> Double {
        max(0, distanceMeters * (1 - Self.clamp(f)))
    }

    /// A quadratic Bézier from `from` to `to`, bowed sideways by 25% of the straight-line length.
    static func fallback(from: GeoPoint, to: GeoPoint) -> DeliveryRoute {
        let count = 32
        let dx = to.longitude - from.longitude
        let dy = to.latitude - from.latitude
        let control = GeoPoint(latitude: (from.latitude + to.latitude) / 2 + dx * 0.25,
                               longitude: (from.longitude + to.longitude) / 2 - dy * 0.25)
        let points = (0..<count).map { index -> GeoPoint in
            let t = Double(index) / Double(count - 1)
            let u = 1 - t
            return GeoPoint(
                latitude: u * u * from.latitude + 2 * u * t * control.latitude + t * t * to.latitude,
                longitude: u * u * from.longitude + 2 * u * t * control.longitude + t * t * to.longitude)
        }
        return DeliveryRoute(points: points, distanceMeters: pathMeters(points), isApproximate: true)
    }

    /// Great-circle distance in metres.
    static func haversineMeters(_ a: GeoPoint, _ b: GeoPoint) -> Double {
        let radius = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * asin(min(1, sqrt(h)))
    }

    static func pathMeters(_ points: [GeoPoint]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { $0 + haversineMeters($1.0, $1.1) }
    }

    private func cumulativeMeters() -> [Double] {
        var result = [0.0]
        for index in points.indices.dropFirst() {
            result.append(result[index - 1] + Self.haversineMeters(points[index - 1], points[index]))
        }
        return result
    }

    private static func clamp(_ value: Double) -> Double {
        value.isNaN ? 0 : min(max(value, 0), 1)
    }
}

/// Where the simulated rider is.
nonisolated struct RiderPosition: Equatable, Sendable {
    /// Nil while the order is confirmed or preparing: the rider is waiting at the restaurant.
    let coordinate: GeoPoint?
    let remainingMeters: Double

    static func make(route: DeliveryRoute, status: DeliveryStatus) -> RiderPosition {
        switch status.stage {
        case .confirmed, .preparing:
            return RiderPosition(coordinate: nil, remainingMeters: route.distanceMeters)
        case .onTheWay:
            let fraction = min(max((status.progress - 0.45) / 0.55, 0), 1)
            return RiderPosition(coordinate: route.point(atFraction: fraction),
                                 remainingMeters: route.remainingMeters(atFraction: fraction))
        case .delivered:
            return RiderPosition(coordinate: route.points.last ?? DeliveryLocations.home, remainingMeters: 0)
        }
    }
}

/// "850 m" under a kilometre, otherwise "1.2 km".
nonisolated enum DistanceFormatter {
    static func string(meters: Double) -> String {
        let value = max(0, meters.isFinite ? meters : 0)
        let roundedMeters = Int((value / 10).rounded()) * 10
        if roundedMeters < 1000 {
            return "\(roundedMeters) m"
        }
        return String(format: "%.1f km", value / 1000)
    }
}
