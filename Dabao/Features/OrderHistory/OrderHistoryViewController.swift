import UIKit

/// The Orders tab: past orders, newest first. Tap one to open its receipt.
final class OrderHistoryViewController: UIViewController {

    private nonisolated enum Section { case orders }

    var presenter: OrderHistoryPresenterProtocol!

    private var rows: [UUID: OrderHistoryCellModel] = [:]

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = EmptyStateView(symbolName: "receipt",
                                            title: "No orders yet",
                                            message: "Your past orders will show up here.")
    private lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Orders"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = DS.Color.background

        setUpTableView()
        setUpEmptyState()
        presenter.viewDidLoad()
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.register(OrderHistoryCell.self, forCellReuseIdentifier: OrderHistoryCell.reuseIdentifier)
        tableView.backgroundColor = DS.Color.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpEmptyState() {
        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        NSLayoutConstraint.activate([
            emptyState.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyState.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, UUID> {
        UITableViewDiffableDataSource<Section, UUID>(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? OrderHistoryCell, let row = self?.rows[id] {
                cell.configure(row)
            }
            return cell
        }
    }
}

// MARK: - OrderHistoryViewProtocol

extension OrderHistoryViewController: OrderHistoryViewProtocol {

    func showOrders(_ orders: [OrderHistoryCellModel]) {
        let previous = rows
        let previousIDs = dataSource.snapshot().itemIdentifiers
        rows = Dictionary(orders.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        // The tracker ticks every second, so skip the update when nothing on screen changed.
        guard previousIDs != orders.map(\.id) || previous != rows else { return }

        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.orders])
        snapshot.appendItems(orders.map(\.id))
        snapshot.reconfigureItems(orders.filter { previous[$0.id] != nil && previous[$0.id] != $0 }.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: view.window != nil)

        tableView.isHidden = orders.isEmpty
        emptyState.isHidden = !orders.isEmpty
    }
}

// MARK: - Table view delegate

extension OrderHistoryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        presenter.didSelectOrder(id: id)
    }
}
