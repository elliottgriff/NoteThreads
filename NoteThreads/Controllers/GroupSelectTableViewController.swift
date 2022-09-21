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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let searchController = UISearchController(searchResultsController: nil)
    
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
        
        fetchNotes()
        fetchSections()
        
        self.groupSelectTableView.delegate = self
        self.groupSelectTableView.dataSource = self
        
        searchController.searchBar.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
        self.groupSelectTableView.tableHeaderView = searchController.searchBar
        groupSelectTableView.backgroundView = UIView(frame: groupSelectTableView.frame)
        groupSelectTableView.backgroundView?.backgroundColor = .systemBackground

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

    // MARK: - Table view data source
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if isFiltering {
            return 1 + filteredGroups.count
        } else {
            return 1 + noteGroup.count
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
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddGroup", for: indexPath) as! AddGroupTableViewCell
            cell.body.text = "New Group"
            cell.backgroundColor = .systemYellow
            return cell
        } else {
            if isFiltering {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupTableViewCell
                guard let title = filteredGroups[indexPath.row - 1].title else { return cell }
                cell.body.text = title
                cell.tag = indexPath.row - 1
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupTableViewCell
                guard let title = noteGroup[indexPath.row - 1].title else { return cell }
                cell.body.text = title
                cell.tag = indexPath.row - 1
                return cell
            }
        }
    }
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
                
                let alert = UIAlertController(title: "Add Group",
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
                        tableView.reloadData()
                    }
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                
        } else {
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @IBSegueAction func enterGroupSegue(_ coder: NSCoder, sender: GroupTableViewCell?, segueIdentifier: String?) -> NotesCollectionViewController? {
        
        guard let index = sender?.tag else { return nil }
        
        if !isSearchBarEmpty {
            print("filtered name", filteredGroups[index].title ?? "No filtered name")
            guard let name = filteredGroups[index].title else { fatalError("no filtered group name") }
            let notesCollectionVC = NotesCollectionViewController(coder: coder, groupName: name)
            notesCollectionVC?.delegate = self
            searchController.isActive = false
            return notesCollectionVC
            

        } else {
            print("non filtered name", noteGroup[index].title ?? "No non-filtered name")
            guard let name = noteGroup[index].title else { fatalError("no non-filtered group name") }
            let notesCollectionVC = NotesCollectionViewController(coder: coder, groupName: name)
            notesCollectionVC?.delegate = self
            searchController.isActive = false
            return notesCollectionVC
            
        }

        
    }

    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
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
                    if note.group == filteredGroups[indexPath.row - 1].title {
                        context.delete(note)
                    }
                }

                context.delete(filteredGroups[indexPath.row - 1])
                filteredGroups.remove(at: indexPath.row - 1)
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
                    if note.group == noteGroup[indexPath.row - 1].title {
                        context.delete(note)
                    }
                }
                
                context.delete(noteGroup[indexPath.row - 1])
                noteGroup.remove(at: indexPath.row - 1)
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
