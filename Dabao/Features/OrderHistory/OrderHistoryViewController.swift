import UIKit

/// The Orders tab: orders on their way, then past orders, newest first.
/// Tap an active order to track it, or a past order's card to open its receipt.
final class OrderHistoryViewController: UIViewController {

    private nonisolated enum Section: Hashable { case active, past }

    var presenter: OrderHistoryPresenterProtocol!

    private var activeRows: [UUID: OrderHistoryCellModel] = [:]
    private var pastRows: [UUID: PastOrderCellModel] = [:]
    private var activeOrder: [UUID] = []
    private var pastOrder: [UUID] = []
    private var hasShownOrders = false

    private let tableView = OrdersTableView(frame: .zero, style: .plain)
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
        tableView.register(PastOrderCell.self, forCellReuseIdentifier: PastOrderCell.reuseIdentifier)
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier)
        tableView.backgroundColor = DS.Color.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 52
        tableView.sectionHeaderTopPadding = 0
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
            guard let self else { return UITableViewCell() }
            if let row = self.pastRows[id] {
                let cell = tableView.dequeueReusableCell(withIdentifier: PastOrderCell.reuseIdentifier, for: indexPath)
                if let cell = cell as? PastOrderCell {
                    cell.configure(row)
                    cell.onSelectBody = { [weak self] in self?.presenter.didSelectOrder(id: id) }
                    cell.onReorder = { [weak self] in self?.presenter.didTapReorder(id: id) }
                    cell.onRate = { [weak self] stars in self?.presenter.didRate(id: id, stars: stars) }
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? OrderHistoryCell, let row = self.activeRows[id] {
                cell.configure(row)
            }
            return cell
        }
    }
}

/// Past order cards are mostly controls (body, Reorder, stars), so let a drag that starts on one still scroll.
private final class OrdersTableView: UITableView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}

// MARK: - OrderHistoryViewProtocol

extension OrderHistoryViewController: OrderHistoryViewProtocol {

    func showOrders(active: [OrderHistoryCellModel], past: [PastOrderCellModel]) {
        let previousActive = activeRows
        let previousPast = pastRows
        let newActiveOrder = active.map(\.id)
        let newPastOrder = past.map(\.id)
        let newActive = Dictionary(active.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let newPast = Dictionary(past.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        // The tracker ticks every second, so skip the update when nothing on screen changed.
        guard !hasShownOrders || newActiveOrder != activeOrder || newPastOrder != pastOrder
                || newActive != previousActive || newPast != previousPast else { return }

        hasShownOrders = true
        activeRows = newActive
        pastRows = newPast
        activeOrder = newActiveOrder
        pastOrder = newPastOrder

        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        if !active.isEmpty {
            snapshot.appendSections([.active])
            snapshot.appendItems(newActiveOrder, toSection: .active)
        }
        if !past.isEmpty {
            snapshot.appendSections([.past])
            snapshot.appendItems(newPastOrder, toSection: .past)
        }
        // An order that just arrived moves sections, so reconfigure only rows that stayed in the same kind of cell.
        let changed = active.filter { previousActive[$0.id] != nil && previousActive[$0.id] != $0 }.map(\.id)
            + past.filter { previousPast[$0.id] != nil && previousPast[$0.id] != $0 }.map(\.id)
        let moved = Set(newActiveOrder).intersection(previousPast.keys).union(Set(newPastOrder).intersection(previousActive.keys))
        snapshot.reconfigureItems(changed)
        if !moved.isEmpty {
            snapshot.reloadItems(Array(moved))
        }
        dataSource.apply(snapshot, animatingDifferences: view.window != nil)

        let isEmpty = active.isEmpty && past.isEmpty
        tableView.isHidden = isEmpty
        emptyState.isHidden = !isEmpty
    }
}

// MARK: - Table view delegate

extension OrderHistoryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let kind = dataSource.sectionIdentifier(for: section),
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.reuseIdentifier)
                as? SectionHeaderView else { return nil }
        header.configure(title: kind == .active ? "Active orders" : "Past orders")
        return header
    }

    // Past cards handle their own taps (body, Reorder, stars), so only active rows select.
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        dataSource.sectionIdentifier(for: indexPath.section) == .active
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard dataSource.sectionIdentifier(for: indexPath.section) == .active,
              let id = dataSource.itemIdentifier(for: indexPath) else { return }
        presenter.didSelectOrder(id: id)
    }
}
