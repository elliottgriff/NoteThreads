//
//  GroupSelectTableViewController.swift
//  NoteThreads
//
//  Created by elliott on 9/13/22.
//

import UIKit
import CoreData

class GroupSelectTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCollectionViewControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    @IBOutlet weak var groupSelectTableView: UITableView!
    @IBOutlet weak var homeTitleLabel: UITextField!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private var homeTitle = [HomeTitle]()
    private var noteGroup = [NoteGroup]()
    private var filteredGroups = [NoteGroup]()
    private var notes = [Note]()
    private var groupInt: Int?
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchTitle()
        fetchNotes()
        fetchSections()
        
        self.groupSelectTableView.delegate = self
        self.groupSelectTableView.dataSource = self
        
        searchController.searchBar.delegate = self
        navigationItem.leftBarButtonItem = editButtonItem
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
        self.groupSelectTableView.tableHeaderView = searchController.searchBar
        groupSelectTableView.backgroundView = UIView(frame: groupSelectTableView.frame)
        groupSelectTableView.backgroundView?.backgroundColor = .systemBackground
        
        if homeTitle.first?.title == nil {
            homeTitleLabel.text = "Groups"
        } else {
            homeTitleLabel.text = homeTitle.first?.title
        }
        homeTitleLabel.addTarget(self, action: #selector(titleFieldDidChange(_:)), for: .editingChanged)
        homeTitleLabel.addTarget(self, action: #selector(titleFieldDidEnd(_:)), for: .editingDidEnd)
    }
    
    func refresh() {
        print("group delegate fetching")
        fetchNotes()
        fetchSections()
    }

    func fetchSections() {
        let request = NoteGroup.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        
        do {
            noteGroup = try context.fetch(request)
            DispatchQueue.main.async {
                self.groupSelectTableView.reloadData()
            }
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Load Groups",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
    
    func fetchNotes() {
        
        let request = Note.fetchRequest()
        let sort1 = NSSortDescriptor(key: "date", ascending: false)
        
        request.sortDescriptors = [sort1]
        
        do {
            notes = try context.fetch(request)
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Load Notes",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
        
    }
    
    func fetchTitle() {
        
        let request = HomeTitle.fetchRequest()
        
        do {
            homeTitle = try context.fetch(request)
        } catch {
            print("couldn't load title")
        }
        
    }
    
    @objc func titleFieldDidEnd(_ textField: UITextField) {
        
        do {
            if let titleID = homeTitle.first?.objectID {
                let newTitle = try context.existingObject(with: titleID) as! HomeTitle
                newTitle.title = textField.text
                print(newTitle.title, "newtitle")
            } else {
                let newTitle = HomeTitle(context: context)
                newTitle.title = textField.text
                print(newTitle.title, "brand newtitle")
            }
        } catch {
            print("oops")
        }

        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        
        DispatchQueue.main.async {
            self.groupSelectTableView.reloadData()
        }
    }
    
    @objc func titleFieldDidChange(_ textField: UITextField) {

        homeTitleLabel.text = textField.text

    }

    // MARK: - Table view data source
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        titleField.frame = CGRect(x: 10, y: 0, width: tableView.frame.width, height: tableView.frame.height)
//        return titleField
//    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if isFiltering {
            return filteredGroups.count
        } else {
            return noteGroup.count
        }

    }
    
    func filterGroupsForSearchText(_ searchText: String) {
       
        if searchText != "" {
            filteredGroups = noteGroup.filter { (group: NoteGroup) -> Bool in
                return group.title?.lowercased().contains(searchText.lowercased()) ?? false
            }
            fetchNotes()
            fetchSections()
            DispatchQueue.main.async {
                self.groupSelectTableView.reloadData()
            }
            
        } else {
            fetchNotes()
            fetchSections()
            DispatchQueue.main.async {
                self.groupSelectTableView.reloadData()
            }
        }
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        if let filterText = searchBar.text {
            filterGroupsForSearchText(filterText)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        groupSelectTableView.setEditing(editing, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupTableViewCell
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
            if isFiltering {
                guard let title = filteredGroups[indexPath.row].title else { return cell }
                cell.body.text = title
                cell.tag = indexPath.row
                return cell
            } else {
                guard let title = noteGroup[indexPath.row].title else { return cell }
                cell.body.text = title
                cell.tag = indexPath.row
                return cell
            }

    }
    
    
    @IBAction func newGroupPressed(_ sender: Any) {
        let alert = UIAlertController(title: "New Group",
                                      message: "Enter Group Name",
                                      preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let field = alert.textFields?.first,
                    let newGroupTitle = field.text, !newGroupTitle.isEmpty,
                    let context = self?.context else { return }
            
            let newGroup = NoteGroup(context: context)
            newGroup.title = newGroupTitle
            newGroup.date = Date()
            newGroup.sectionIndex = Int32((self?.noteGroup.count)!)
            print(newGroup.sectionIndex)
            do {
                try context.save()
            } catch {
                print("couldn't update new groups")
            }
            self?.fetchSections()
            
            DispatchQueue.main.async {
                self?.groupSelectTableView.reloadData()
            }
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        DispatchQueue.main.async {
            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

    @IBSegueAction func enterGroupSegue(_ coder: NSCoder, sender: GroupTableViewCell?, segueIdentifier: String?) -> NotesCollectionViewController? {
        
        guard let index = sender?.tag else { return nil }
        
        if !isSearchBarEmpty {
            print("filtered name", filteredGroups[index].title ?? "No filtered name")
            guard let name = filteredGroups[index].title else { fatalError("no filtered group name") }
            let notesCollectionVC = NotesCollectionViewController(coder: coder, groupName: name, id: noteGroup[index].objectID.uriRepresentation().absoluteString)
            notesCollectionVC?.delegate = self
            searchController.isActive = false
            return notesCollectionVC

        } else {
            print("non filtered name", noteGroup[index].title ?? "No non-filtered name")
            guard let name = noteGroup[index].title else { fatalError("no non-filtered group name") }
            let notesCollectionVC = NotesCollectionViewController(coder: coder, groupName: name, id: noteGroup[index].objectID.uriRepresentation().absoluteString)
            notesCollectionVC?.delegate = self
            searchController.isActive = false
            return notesCollectionVC
            
        }
    }

    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        fetchSections()
        fetchNotes()
        DispatchQueue.main.async {
            self.groupSelectTableView.reloadData()
        }
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if isFiltering {

                for note in notes {
                    if note.groupID == filteredGroups[indexPath.row].objectID.uriRepresentation().absoluteString {
                        context.delete(note)
                    }
                }

                context.delete(filteredGroups[indexPath.row])
                filteredGroups.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)

                do {
                    try context.save()
                    fetchNotes()
                    fetchSections()
                } catch {
                    print("cannot delete item")
                }

                DispatchQueue.main.async {
                    tableView.reloadData()
                }

            } else {
                
                for note in notes {
                    if note.groupID == noteGroup[indexPath.row].objectID.uriRepresentation().absoluteString {
                        context.delete(note)
                    }
                }
                
                context.delete(noteGroup[indexPath.row])
                noteGroup.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                do {
                    try context.save()
                    fetchNotes()
                    fetchSections()
                } catch {
                    print("cannot delete item")
                }
                
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }

        } else if editingStyle == .insert {
        }    
    }
    
    

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    // Override to support conditional rearranging of the table view.
//    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the item to be re-orderable.
//        return true
//    }


}
