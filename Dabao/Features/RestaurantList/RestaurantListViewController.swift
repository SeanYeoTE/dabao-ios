import UIKit

/// The Home tab: search, cuisine chips and a list of restaurants.
///
/// This screen uses plain MVC. The view controller reads the catalogue, holds the filter state,
/// and feeds a diffable data source. Compare it with the Menu module, which uses VIPER.
final class RestaurantListViewController: UIViewController {

    private nonisolated enum Section { case restaurants }
    private static let allChipTitle = "All"

    private let catalog: CatalogStore
    private let cart: CartStore

    private var selectedCuisine: String?
    private var query = ""

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let searchController = UISearchController(searchResultsController: nil)
    private let chipBar = ChipBar()
    private let headerContainer = UIView()
    private let cartBar = StickyCartBar()
    private lazy var emptyState: EmptyStateView = {
        let view = EmptyStateView(symbolName: "magnifyingglass",
                                  title: "No restaurants found",
                                  message: "Try a different search or cuisine.",
                                  actionTitle: "Clear filters")
        view.onAction = { [weak self] in self?.clearFilters() }
        return view
    }()
    private lazy var dataSource = makeDataSource()

    init(catalog: CatalogStore = .shared, cart: CartStore = .shared) {
        self.catalog = catalog
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dabao"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = DS.Color.background

        setUpSearch()
        setUpTableView()
        setUpCartBar()
        setUpSpinner()
        loadRestaurants()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: nil)
        cartDidChange()
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

    // MARK: Set up

    private func setUpSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search restaurants and dishes"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.register(RestaurantCardCell.self, forCellReuseIdentifier: RestaurantCardCell.reuseIdentifier)
        tableView.backgroundColor = DS.Color.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        chipBar.translatesAutoresizingMaskIntoConstraints = false
        chipBar.onSelect = { [weak self] title in
            self?.didSelectChip(title)
        }
        headerContainer.addSubview(chipBar)
        NSLayoutConstraint.activate([
            chipBar.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            chipBar.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            chipBar.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            chipBar.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])
        tableView.tableHeaderView = headerContainer
    }

    private func setUpCartBar() {
        cartBar.translatesAutoresizingMaskIntoConstraints = false
        cartBar.isHidden = true
        cartBar.onTap = { [weak self] in self?.showCartTab() }
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

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, String> {
        UITableViewDiffableDataSource<Section, String>(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantCardCell.reuseIdentifier,
                                                     for: indexPath)
            if let cell = cell as? RestaurantCardCell, let restaurant = self?.catalog.restaurant(id: id) {
                cell.configure(RestaurantCardModel(restaurant: restaurant))
            }
            return cell
        }
    }

    // MARK: Data

    private func loadRestaurants() {
        spinner.startAnimating()
        catalog.load { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()
            switch result {
            case .success:
                self.showChips()
                self.applyFilters(animated: false)
            case .failure:
                self.showError()
            }
        }
    }

    private func applyFilters(animated: Bool = true) {
        let ids = catalog.restaurants(cuisine: selectedCuisine, query: query).map(\.id)
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.restaurants])
        snapshot.appendItems(ids)
        dataSource.apply(snapshot, animatingDifferences: animated)
        tableView.backgroundView = ids.isEmpty && catalog.isLoaded ? emptyState : nil
    }

    private func didSelectChip(_ title: String?) {
        // "All" means no cuisine filter, and deselecting a chip falls back to "All".
        selectedCuisine = (title == Self.allChipTitle) ? nil : title
        showChips()
        applyFilters()
    }

    private func showChips() {
        chipBar.setChips([Self.allChipTitle] + catalog.cuisines, selected: selectedCuisine ?? Self.allChipTitle)
    }

    private func clearFilters() {
        selectedCuisine = nil
        query = ""
        searchController.searchBar.text = nil
        searchController.isActive = false
        showChips()
        applyFilters()
    }

    @objc private func cartDidChange() {
        let count = cart.itemCount
        cartBar.isHidden = count == 0
        if count > 0 {
            cartBar.configure(itemCount: count, totalText: PriceFormatter.string(from: cart.subtotal))
        }
        view.setNeedsLayout()
    }

    private func sizeTableHeader() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let height = headerContainer.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        if headerContainer.frame.size != CGSize(width: width, height: height) {
            headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableHeaderView = headerContainer
        }
    }

    private func showError() {
        let alert = UIAlertController(title: "Couldn't load restaurants",
                                      message: "Please try again later.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try again", style: .default) { [weak self] _ in
            self?.loadRestaurants()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Search

extension RestaurantListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let newQuery = searchController.searchBar.text ?? ""
        guard newQuery != query else { return }
        query = newQuery
        applyFilters()
    }
}

// MARK: - Table view delegate

extension RestaurantListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let restaurant = catalog.restaurant(id: id) else { return }

        // The Menu screen is a VIPER module. We ask its router to build it for us.
        let menu = MenuRouter.createModule(restaurant: restaurant, cart: cart)
        navigationController?.pushViewController(menu, animated: true)
    }
}
