import Network
import Foundation

// MARK: - NetworkMonitor
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.cinetrack.networkmonitor")

    private(set) var isConnected: Bool = true
    private(set) var connectionType: NWInterface.InterfaceType = .wifi

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            self?.connectionType = self?.getConnectionType(path) ?? .wifi
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> NWInterface.InterfaceType {
        if path.usesInterfaceType(.wifi)        { return .wifi }
        if path.usesInterfaceType(.cellular)    { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .other
    }

    deinit {
        monitor.cancel()
    }
}
