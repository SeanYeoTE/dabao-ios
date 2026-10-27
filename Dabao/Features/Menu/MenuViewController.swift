import UIKit

/// The View. It doesn't decide anything: it shows what the presenter tells it to,
/// and forwards taps to the presenter.
final class MenuViewController: UIViewController {

    var presenter: MenuPresenterProtocol!

    private var sections: [MenuSectionViewModel] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let headerView = MenuHeaderView()
    private let cartBar = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        setUpTableView()
        setUpCartBar()
        setUpSpinner()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: nil)

        presenter.viewDidLoad()
    }

    @objc private func cartDidChange() {
        presenter.cartDidChange()
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(MenuItemCell.self, forCellReuseIdentifier: MenuItemCell.reuseIdentifier)
        tableView.allowsSelection = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpCartBar() {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor(named: "AccentColor")
        cartBar.configuration = config
        cartBar.translatesAutoresizingMaskIntoConstraints = false
        cartBar.isHidden = true
        cartBar.addAction(UIAction { [weak self] _ in
            self?.presenter.didTapCartBar()
        }, for: .touchUpInside)
        view.addSubview(cartBar)

        NSLayoutConstraint.activate([
            cartBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            cartBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            cartBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            cartBar.heightAnchor.constraint(equalToConstant: 50)
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
        headerView.frame.size = headerView.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height))
        tableView.tableHeaderView = headerView
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

    func showCartBar(title: String?) {
        cartBar.isHidden = (title == nil)
        cartBar.configuration?.title = title
        tableView.contentInset.bottom = title == nil ? 0 : 74
    }

    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table view data source

extension MenuViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuItemCell.reuseIdentifier,
                                                 for: indexPath) as! MenuItemCell
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.configure(with: row)
        cell.onAdd = { [weak self] in self?.presenter.didTapAdd(itemID: row.id) }
        cell.onRemove = { [weak self] in self?.presenter.didTapRemove(itemID: row.id) }
        return cell
    }
}

// MARK: - Header

final class MenuHeaderView: UIView {

    private let subtitleLabel = UILabel()
    private let closedLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel

        closedLabel.text = "Closed now. You can browse, but not order."
        closedLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        closedLabel.textColor = .white
        closedLabel.backgroundColor = .systemRed
        closedLabel.textAlignment = .center
        closedLabel.layer.cornerRadius = 8
        closedLabel.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [subtitleLabel, closedLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            closedLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with header: MenuHeaderViewModel) {
        subtitleLabel.text = header.subtitle
        closedLabel.isHidden = header.isOpen
    }
}
