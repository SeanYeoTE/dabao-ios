import UIKit

/// The first screen: a list of restaurants.
///
/// This screen uses plain MVC. The view controller fetches the data, holds it,
/// and configures the table view. Compare it with the Menu module, which uses VIPER.
final class RestaurantListViewController: UIViewController {

    private let service: RestaurantServicing
    private var restaurants: [Restaurant] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .large)

    init(service: RestaurantServicing = RestaurantService()) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dabao"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        setUpTableView()
        setUpSpinner()
        loadRestaurants()
    }

    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RestaurantCell.self, forCellReuseIdentifier: RestaurantCell.reuseIdentifier)
        tableView.rowHeight = 88
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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

    private func loadRestaurants() {
        spinner.startAnimating()
        service.fetchRestaurants { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()
            switch result {
            case .success(let restaurants):
                self.restaurants = restaurants
                self.tableView.reloadData()
            case .failure:
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(title: "Couldn't load restaurants",
                                      message: "Please try again later.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RestaurantListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        restaurants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantCell.reuseIdentifier,
                                                 for: indexPath) as! RestaurantCell
        cell.configure(with: restaurants[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let restaurant = restaurants[indexPath.row]

        // The Menu screen is a VIPER module. We ask its router to build it for us.
        let menu = MenuRouter.createModule(restaurant: restaurant, cart: CartStore.shared)
        navigationController?.pushViewController(menu, animated: true)
    }
}
