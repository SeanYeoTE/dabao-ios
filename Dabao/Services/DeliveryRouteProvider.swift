import Foundation
import MapKit

/// Finds the driving route for an order, once, and remembers it. Falls back to a curved path when
/// directions aren't available. Not persisted: a route is cheap to ask for again after a relaunch.
@MainActor
final class DeliveryRouteProvider {

    static let shared = DeliveryRouteProvider()

    private static let timeoutSeconds: UInt64 = 8

    private struct Pending {
        let token: UUID
        let start: GeoPoint
        var completions: [(DeliveryRoute) -> Void]
        let timeoutTask: Task<Void, Never>
        let fetchTask: Task<Void, Never>
    }

    private var cache: [UUID: DeliveryRoute] = [:]
    private var pending: [UUID: Pending] = [:]

    /// Completes on the main thread, exactly once. Synchronously on a cache hit.
    func route(for order: PastOrder, completion: @escaping (DeliveryRoute) -> Void) {
        if let cached = cache[order.id] {
            completion(cached)
            return
        }
        if var existing = pending[order.id] {
            existing.completions.append(completion)
            pending[order.id] = existing
            return
        }

        let start = restaurantCoordinate(for: order)
        let home = DeliveryLocations.home
        let orderID = order.id
        let token = UUID()

        if LaunchOptions.offlineMap {
            let fallback = DeliveryRoute.fallback(from: start, to: home)
            cache[orderID] = fallback
            completion(fallback)
            return
        }

        let fetchTask = Task { [weak self] in
            let route = await Self.fetchRoute(from: start, to: home)
            self?.finish(orderID: orderID, token: token, route: route)
        }
        let timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.timeoutSeconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.finish(orderID: orderID, token: token, route: nil)
        }
        pending[orderID] = Pending(token: token, start: start, completions: [completion],
                                   timeoutTask: timeoutTask, fetchTask: fetchTask)
    }

    func restaurantCoordinate(for order: PastOrder) -> GeoPoint {
        DeliveryLocations.coordinate(forArea: order.restaurantArea, restaurantID: order.restaurantID)
    }

    /// Whichever of the directions result and the timeout arrives first wins; the other is ignored.
    private func finish(orderID: UUID, token: UUID, route: DeliveryRoute?) {
        guard let entry = pending[orderID], entry.token == token else { return }
        pending[orderID] = nil
        entry.timeoutTask.cancel()
        entry.fetchTask.cancel()

        let resolved: DeliveryRoute
        if let route {
            resolved = route
        } else {
            resolved = DeliveryRoute.fallback(from: entry.start, to: DeliveryLocations.home)
        }
        cache[orderID] = resolved
        for completion in entry.completions {
            completion(resolved)
        }
    }

    nonisolated private static func fetchRoute(from start: GeoPoint, to end: GeoPoint) async -> DeliveryRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate(start)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate(end)))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { return nil }
            let points = polylinePoints(of: route.polyline)
            guard points.count >= 2 else { return nil }
            let distance = route.distance > 0 ? route.distance : DeliveryRoute.pathMeters(points)
            return DeliveryRoute(points: points, distanceMeters: distance, isApproximate: false)
        } catch {
            return nil
        }
    }

    nonisolated private static func polylinePoints(of polyline: MKPolyline) -> [GeoPoint] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        return coordinates.map { GeoPoint(latitude: $0.latitude, longitude: $0.longitude) }
    }

    nonisolated private static func coordinate(_ point: GeoPoint) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    }
}
