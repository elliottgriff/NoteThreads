//
//  GroupTableView.swift
//  NoteThreads
//
//  Created by elliott on 9/19/22.
//

import UIKit

class GroupTableView: UITableView {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private var noteGroup = [NoteGroup]()
    private var filteredGroups: [NoteGroup] = []
    private var notes = [Note]()
    private var groupInt: Int?
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    func filterGroupsForSearchText(_ searchText: String) {
        filteredGroups = noteGroup.filter { (group: NoteGroup) -> Bool in
            return group.title?.lowercased().contains(searchText.lowercased()) ?? false
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        if let filterText = searchBar.text {
            filterGroupsForSearchText(filterText)
        }
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
                self.tableView.reloadData()
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering {
            return filteredGroups.count + 1
        }
        
        return 1 + noteGroup.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                    do {
                        try context.save()
                    } catch {
                        print("couldn't update new groups")
                    }
                    self?.fetchSections()
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                
        } else {
            groupInt = indexPath.row - 1
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }


    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            context.delete(noteGroup[indexPath.row - 1])
            for note in notes {
                if note.group == noteGroup[indexPath.row - 1].title {
                    print(note)
                    context.delete(note)
                }
            }
            do {
                try context.save()
                fetchNotes()
                fetchSections()
            } catch {
                print("cannot delete item")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        } else if editingStyle == .insert {
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    @IBSegueAction func enterGroupSegue(_ coder: NSCoder, sender: NoteCollectionViewCell?, segueIdentifier: String?) -> NotesCollectionViewController? {

        if let groupInt = sender?.tag {
        let notesCollectionVC = NotesCollectionViewController(coder: coder, groupInt: groupInt)
            notesCollectionVC?.delegate = self
        return notesCollectionVC
        } else {
            return nil
        }
        
    }

}
