import UIKit

/// The View. It doesn't decide anything: it shows what the presenter tells it to,
/// and forwards taps to the presenter.
final class MenuViewController: UIViewController {

    var presenter: MenuPresenterProtocol!

    private var sections: [MenuSectionViewModel] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let headerView = MenuHeaderView()
    private let cartBar = StickyCartBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
        navigationItem.largeTitleDisplayMode = .never

        setUpTableView()
        setUpCartBar()
        setUpSpinner()

        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeader()
        let bottomInset = cartBar.isHidden ? 0 : cartBar.bounds.height + DS.Spacing.l * 2
        if tableView.contentInset.bottom != bottomInset {
            tableView.contentInset.bottom = bottomInset
            tableView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MenuItemCell.self, forCellReuseIdentifier: MenuItemCell.reuseIdentifier)
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier)
        tableView.allowsSelection = false
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

    private func setUpCartBar() {
        cartBar.translatesAutoresizingMaskIntoConstraints = false
        cartBar.isHidden = true
        cartBar.onTap = { [weak self] in self?.presenter.didTapCartBar() }
        view.addSubview(cartBar)

        NSLayoutConstraint.activate([
            cartBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.l),
            cartBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.l),
            cartBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.l)
        ])
    }

    private func setUpSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// A table header isn't laid out by Auto Layout, so we measure it ourselves.
    private func sizeTableHeader() {
        guard tableView.tableHeaderView != nil else { return }
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height = headerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        if headerView.frame.size != CGSize(width: width, height: height) {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableHeaderView = headerView
        }
    }

    private func indexPath(forItemID id: String) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            if let rowIndex = section.rows.firstIndex(where: { $0.id == id }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

// MARK: - MenuViewProtocol

extension MenuViewController: MenuViewProtocol {

    func showLoading(_ isLoading: Bool) {
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    func showHeader(_ header: MenuHeaderViewModel) {
        title = header.title
        headerView.configure(with: header)
        tableView.tableHeaderView = headerView
        view.setNeedsLayout()
    }

    func showSections(_ sections: [MenuSectionViewModel]) {
        self.sections = sections
        tableView.reloadData()
    }

    func reloadRow(_ row: MenuItemViewModel) {
        guard let indexPath = indexPath(forItemID: row.id) else { return }
        var rows = sections[indexPath.section].rows
        rows[indexPath.row] = row
        sections[indexPath.section] = MenuSectionViewModel(title: sections[indexPath.section].title, rows: rows)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func showCartBar(_ bar: CartBarViewModel?) {
        cartBar.isHidden = (bar == nil)
        if let bar {
            cartBar.configure(itemCount: bar.itemCount, totalText: bar.totalText)
        }
        view.setNeedsLayout()
    }

    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showReplaceCartConfirmation(currentRestaurantName: String, onReplace: @escaping () -> Void) {
        let alert = UIAlertController(title: "Start a new cart?",
                                      message: "Your cart has items from \(currentRestaurantName). Adding this dish will clear it.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Replace cart", style: .destructive) { _ in onReplace() })
        present(alert, animated: true)
    }
}

// MARK: - Table view data source and delegate

extension MenuViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.reuseIdentifier)
        (header as? SectionHeaderView)?.configure(title: sections[section].title)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuItemCell.reuseIdentifier, for: indexPath)
        guard let itemCell = cell as? MenuItemCell else { return cell }
        let row = sections[indexPath.section].rows[indexPath.row]
        itemCell.configure(with: row)
        itemCell.onAdd = { [weak self] in self?.presenter.didTapAdd(itemID: row.id) }
        itemCell.onRemove = { [weak self] in self?.presenter.didTapRemove(itemID: row.id) }
        return itemCell
    }
}
