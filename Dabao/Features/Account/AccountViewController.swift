import UIKit

/// The Account tab: who you are, what you've ordered, where it goes, and a way to the About screen.
final class AccountViewController: UITableViewController {

    private enum Section: Int, CaseIterable {
        case orders, address, more

        var title: String {
            switch self {
            case .orders: "Your orders"
            case .address: "Delivery address"
            case .more: "More"
            }
        }
    }

    var presenter: AccountPresenterProtocol!

    private var model: AccountViewModel?
    private let headerView = ProfileHeaderView()
    private let statsCellID = "Stats"
    private let plainCellID = "Plain"

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", primaryAction: UIAction { [weak self] _ in
            self?.presenter.didTapEdit()
        })

        tableView.backgroundColor = DS.Color.background
        tableView.register(StatsCell.self, forCellReuseIdentifier: statsCellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: plainCellID)
        headerView.onAddDetails = { [weak self] in self?.presenter.didTapEdit() }
        tableView.tableHeaderView = headerView

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.sizeHeaderToFit()
        }
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    /// Table headers don't self-size, so measure the header at the table's width and reassign it when the height changes.
    private func sizeHeaderToFit() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let size = headerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        guard headerView.frame.size.height != size.height || headerView.frame.width != width else { return }
        headerView.frame = CGRect(origin: .zero, size: CGSize(width: width, height: size.height))
        tableView.tableHeaderView = headerView
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section) ?? .more
        if section == .orders, let stats = model?.stats,
           let cell = tableView.dequeueReusableCell(withIdentifier: statsCellID, for: indexPath) as? StatsCell {
            cell.configure(stats)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: plainCellID, for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()
        content.textProperties.color = DS.Color.textPrimary
        content.textProperties.font = DS.Font.body
        content.secondaryTextProperties.color = DS.Color.textSecondary
        content.secondaryTextProperties.font = DS.Font.subheadline
        content.imageProperties.tintColor = DS.Color.brand
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.accessibilityTraits = .staticText

        switch section {
        case .orders:
            content.text = "No orders yet"
            content.secondaryText = "Your stats will show up after your first order."
        case .address:
            content.image = UIImage(systemName: "mappin.and.ellipse")
            content.text = "Home"
            content.secondaryText = "Ngee Ann Polytechnic"
        case .more:
            content.image = UIImage(systemName: "info.circle")
            content.text = "About Dabao"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.accessibilityTraits = .button
        }
        content.textProperties.adjustsFontForContentSizeCategory = true
        content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        cell.contentConfiguration = content
        cell.backgroundColor = DS.Color.surface
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == Section.more.rawValue
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == Section.more.rawValue {
            presenter.didSelectAbout()
        }
    }
}

extension AccountViewController: AccountViewProtocol {

    func show(_ model: AccountViewModel) {
        let statsChanged = model.stats != self.model?.stats
        self.model = model
        headerView.configure(model.header)
        sizeHeaderToFit()
        if statsChanged, isViewLoaded {
            tableView.reloadSections(IndexSet(integer: Section.orders.rawValue), with: .none)
        }
    }
}

/// One cell holding the row of stat tiles.
private final class StatsCell: UITableViewCell {

    private let statsView = StatsRowView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = DS.Color.surface
        statsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsView)
        statsView.pin(to: contentView, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.m,
                                                            bottom: DS.Spacing.m, right: DS.Spacing.m))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ items: [StatItem]) {
        statsView.configure(items)
    }
}
