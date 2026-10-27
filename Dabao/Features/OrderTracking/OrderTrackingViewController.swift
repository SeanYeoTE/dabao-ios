import UIKit

/// Where an order is: ETA, the four-stage timeline, then the items and the total. Updates live from the tracker.
final class OrderTrackingViewController: UIViewController {

    var presenter: OrderTrackingPresenterProtocol!
    let orderID: UUID

    private var lines: [ReceiptLineViewModel] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerView = OrderTrackingHeaderView()
    private let summaryView = PriceSummaryView()
    private let footerView = UIView()
    private var hasHeader = false
    private var hasSummary = false

    init(orderID: UUID) {
        self.orderID = orderID
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Your order"
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

// MARK: - OrderTrackingViewProtocol

extension OrderTrackingViewController: OrderTrackingViewProtocol {

    func showHeader(_ header: OrderTrackingHeaderViewModel) {
        headerView.configure(header)
        if !hasHeader {
            hasHeader = true
            tableView.tableHeaderView = headerView
        }
        view.setNeedsLayout()
    }

    func showTimeline(_ timeline: OrderTrackingTimelineViewModel) {
        headerView.configureTimeline(timeline, animated: view.window != nil)
    }

    func showLines(_ lines: [ReceiptLineViewModel]) {
        guard lines != self.lines else { return }
        self.lines = lines
        tableView.reloadData()
    }

    func showSummary(_ summary: ReceiptSummaryViewModel) {
        summaryView.configure(rows: [("Subtotal", summary.subtotalText), ("Delivery", summary.deliveryText)],
                              totalTitle: "Total",
                              totalValue: summary.totalText)
        if !hasSummary {
            hasSummary = true
            tableView.tableFooterView = footerView
        }
        view.setNeedsLayout()
    }
}

// MARK: - Table view data source

extension OrderTrackingViewController: UITableViewDataSource {

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
