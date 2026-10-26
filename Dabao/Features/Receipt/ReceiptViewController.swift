import UIKit

/// A read-only receipt: header, one row per dish, then the totals. There's deliberately no reorder button.
final class ReceiptViewController: UIViewController {

    var presenter: ReceiptPresenterProtocol!

    private var lines: [ReceiptLineViewModel] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerView = ReceiptHeaderView()
    private let summaryView = PriceSummaryView()
    private let footerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Receipt"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DS.Color.background

        setUpTableView()
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        size(headerView, asHeader: true)
        size(footerView, asHeader: false)
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(ReceiptLineCell.self, forCellReuseIdentifier: ReceiptLineCell.reuseIdentifier)
        tableView.allowsSelection = false
        tableView.backgroundColor = DS.Color.background
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        summaryView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(summaryView)
        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: DS.Spacing.l),
            summaryView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: DS.Spacing.l),
            summaryView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -DS.Spacing.l),
            summaryView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -DS.Spacing.xl)
        ])
    }

    /// Table headers and footers aren't laid out by Auto Layout, so we measure them ourselves.
    private func size(_ headerOrFooter: UIView, asHeader: Bool) {
        let width = tableView.bounds.width
        guard width > 0, (asHeader ? tableView.tableHeaderView : tableView.tableFooterView) != nil else { return }
        let height = headerOrFooter.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        guard headerOrFooter.frame.size != CGSize(width: width, height: height) else { return }
        headerOrFooter.frame = CGRect(x: 0, y: 0, width: width, height: height)
        if asHeader {
            tableView.tableHeaderView = headerOrFooter
        } else {
            tableView.tableFooterView = headerOrFooter
        }
    }
}

// MARK: - ReceiptViewProtocol

extension ReceiptViewController: ReceiptViewProtocol {

    func showHeader(_ header: ReceiptHeaderViewModel) {
        headerView.configure(restaurantName: header.restaurantName,
                             dateText: header.dateText,
                             symbolName: header.symbolName,
                             tint: UIColor(hex: header.colorHex))
        tableView.tableHeaderView = headerView
        view.setNeedsLayout()
    }

    func showLines(_ lines: [ReceiptLineViewModel]) {
        self.lines = lines
        tableView.reloadData()
    }

    func showSummary(_ summary: ReceiptSummaryViewModel) {
        summaryView.configure(rows: [("Subtotal", summary.subtotalText), ("Delivery", summary.deliveryText)],
                              totalTitle: "Total",
                              totalValue: summary.totalText)
        tableView.tableFooterView = footerView
        view.setNeedsLayout()
    }
}

// MARK: - Table view data source

extension ReceiptViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ReceiptLineCell {
            let line = lines[indexPath.row]
            cell.configure(quantityText: line.quantityText, name: line.name, notes: line.notes, priceText: line.priceText)
        }
        return cell
    }
}
