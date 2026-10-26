import UIKit

/// The Cart tab. Plain MVC: the view controller reads straight from CartStore
/// and feeds a diffable data source keyed by each line's UUID.
final class CartViewController: UIViewController {

    private nonisolated enum Section { case lines }

    private let cart: CartStore
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let summaryView = PriceSummaryView()
    private let footerView = UIView()
    private let placeOrderButton = PrimaryButton(title: "Place order")
    private lazy var emptyState: EmptyStateView = {
        let view = EmptyStateView(symbolName: "bag",
                                  title: "Your cart is empty",
                                  message: "Add something tasty from a restaurant.",
                                  actionTitle: "Browse restaurants")
        view.onAction = { [weak self] in self?.showHomeTab() }
        return view
    }()
    private lazy var dataSource = makeDataSource()

    init(cart: CartStore = .shared) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = DS.Color.background

        setUpTableView()
        setUpFooter()
        setUpEmptyState()
        refresh()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableFooter()
    }

    // MARK: Set up

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.register(CartLineCell.self, forCellReuseIdentifier: CartLineCell.reuseIdentifier)
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier)
        tableView.backgroundColor = DS.Color.background
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpFooter() {
        placeOrderButton.addAction(UIAction { [weak self] _ in self?.confirmPlaceOrder() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [summaryView, placeOrderButton])
        stack.axis = .vertical
        stack.spacing = DS.Spacing.l
        stack.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: footerView.topAnchor, constant: DS.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: DS.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -DS.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -DS.Spacing.l)
        ])
        tableView.tableFooterView = footerView
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
            let cell = tableView.dequeueReusableCell(withIdentifier: CartLineCell.reuseIdentifier, for: indexPath)
            guard let self, let lineCell = cell as? CartLineCell, let line = self.cart.line(id: id) else { return cell }
            lineCell.configure(with: line)
            lineCell.onQuantityChange = { [weak self] quantity in
                self?.cart.setQuantity(lineID: id, to: quantity)
            }
            lineCell.onEditNotes = { [weak self] in self?.editNotes(lineID: id) }
            return lineCell
        }
    }

    // MARK: Data

    @objc private func cartDidChange() {
        refresh()
    }

    private func refresh() {
        let ids = cart.lines.map(\.id)
        let previous = Set(dataSource.snapshot().itemIdentifiers)

        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.lines])
        snapshot.appendItems(ids)
        // Same line, new quantity or notes: refresh the cell in place instead of replacing it.
        snapshot.reconfigureItems(ids.filter(previous.contains))
        dataSource.apply(snapshot, animatingDifferences: view.window != nil)

        let isEmpty = ids.isEmpty
        tableView.isHidden = isEmpty
        emptyState.isHidden = !isEmpty
        (tableView.headerView(forSection: 0) as? SectionHeaderView)?.configure(title: cart.restaurant?.name ?? "")

        summaryView.configure(rows: [("Subtotal", PriceFormatter.string(from: cart.subtotal)),
                                     ("Delivery", PriceFormatter.string(from: cart.deliveryFee))],
                              totalTitle: "Total",
                              totalValue: PriceFormatter.string(from: cart.total))
        placeOrderButton.configuration?.title = "Place order · \(PriceFormatter.string(from: cart.total))"
        view.setNeedsLayout()
    }

    private func sizeTableFooter() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height = footerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        if footerView.frame.size != CGSize(width: width, height: height) {
            footerView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableFooterView = footerView
        }
    }

    private func showHomeTab() {
        tabBarController?.selectedIndex = 0
    }

    // MARK: Actions

    private func editNotes(lineID: UUID) {
        guard let line = cart.line(id: lineID) else { return }
        let alert = UIAlertController(title: "Notes for \(line.item.name)",
                                      message: "Anything the kitchen should know?",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.text = line.notes
            field.placeholder = "e.g. No chilli"
            field.autocapitalizationType = .sentences
            field.clearButtonMode = .whileEditing
            field.accessibilityLabel = "Notes"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            self?.cart.setNotes(lineID: lineID, to: alert?.textFields?.first?.text ?? "")
        })
        present(alert, animated: true)
    }

    private func confirmPlaceOrder() {
        let total = PriceFormatter.string(from: cart.total)
        let alert = UIAlertController(title: "Order placed!",
                                      message: "We've charged \(total). Your food is on the way (not really, this is a demo).",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yay", style: .default) { [weak self] _ in
            self?.cart.clear()
        })
        present(alert, animated: true)
    }
}

// MARK: - Table view delegate

extension CartViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        editNotes(lineID: id)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.reuseIdentifier)
        (header as? SectionHeaderView)?.configure(title: cart.restaurant?.name ?? "")
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            self?.cart.removeLine(id: id)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
