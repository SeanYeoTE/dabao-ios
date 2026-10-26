import UIKit

/// The About tab: a short blurb and the list of contributors.
final class AboutViewController: UITableViewController {

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = DS.Color.background
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Dabao" : "Made by"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : Credits.contributors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if indexPath.section == 0 {
            content.text = "A pretend food delivery app for learning UIKit. \"Dabao\" is Singlish for takeaway. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")."
            content.textProperties.numberOfLines = 0
        } else {
            content.text = Credits.contributors[indexPath.row]
        }
        content.textProperties.color = DS.Color.textPrimary
        content.textProperties.adjustsFontForContentSizeCategory = true
        cell.contentConfiguration = content
        cell.backgroundColor = DS.Color.surface
        cell.selectionStyle = .none
        return cell
    }
}
