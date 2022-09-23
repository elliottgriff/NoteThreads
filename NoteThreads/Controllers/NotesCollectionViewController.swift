//
//  ViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/24/22.
//

import UIKit
import CoreData
import IQKeyboardManagerSwift

protocol NoteCellDelegate: UICollectionViewCell {
    func toggle()
}

protocol NotesCollectionViewControllerDelegate: AnyObject {
    func refresh()
}

class NotesCollectionViewController: UICollectionViewController, NewNoteViewControllerDelegate, EditNoteDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchBarDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private let reuseIdentifier = "NoteCell"
    private let newNoteSegue = "NewNote"
    
    private var notes = [Note]()
    private var filteredNotes = [Note]()
    private var groups = [NoteGroup]()
    
    var editSwitch = false
    var groupName: String?
    var groupID: String?
    
    private var titleField = UITextField()
    
    weak var cellDelegate: NoteCellDelegate?
    weak var delegate: NotesCollectionViewControllerDelegate?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
        self.navigationItem.searchController = searchController
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        collectionView.dragInteractionEnabled = true
        
        collectionView.register(HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier)
        
        fetchSections()
        fetchNotes()
        
        IQKeyboardManager.shared.enable = false
        
        if let groupName = groupName {
            titleField.text = groupName
            titleField.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
            titleField.addTarget(self, action: #selector(titleFieldDidChange(_:)), for: .editingChanged)
            titleField.addTarget(self, action: #selector(titleFieldDidEnd(_:)), for: .editingDidEnd)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier, for: indexPath) as! HeaderCollectionReusableView
            titleField.frame = CGRect(x: 0, y: 0, width: reusableView.frame.width, height: reusableView.frame.height)
            reusableView.addSubview(titleField)
            return reusableView
            
        default:
            fatalError("wrong headerView kind")
        }
    }
    
    @objc func titleFieldDidEnd(_ textField: UITextField) {
        
        guard let groupID = groupID else { return }
        guard let groupURL = URL(string: groupID) else { return }
        guard let convertedGroupID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: groupURL) else { return }
        do {
            let group = try context.existingObject(with: convertedGroupID) as! NoteGroup
            group.title = textField.text
        } catch {
            print("oops")
        }
        
        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        delegate?.refresh()
        fetchSections()
        fetchNotes()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc func titleFieldDidChange(_ textField: UITextField) {

        titleField.text = textField.text

    }
    
    init?(coder: NSCoder, groupName: String, id: String) {
        self.groupName = groupName
        self.groupID = id
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func newSectionPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Add Section",
                                      message: "Enter Section Name",
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
                print("couldn't update new sections")
            }
            self?.fetchSections()
            
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
    }
    
    
    @IBAction func editPressed(_ sender: Any) {
        
        if editSwitch == false {
            editSwitch = true
        } else {
            editSwitch = false
        }
        collectionView.reloadData()
        
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
    
        fetchNotes()

        let note = notes[sender.tag]
        let alert = UIAlertController(title: "Delete Note?",
                                      message: note.body,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
            self.deleteItem(item: note)
        }))
        present(alert, animated: true)
        
    }

    func deleteItem(item: Note) {
        
        context.delete(item)
        
        do {
            try context.save()
            fetchNotes()
            fetchSections()
        } catch {
            print("cannot delete item")
        }
    }
    
    func deleteSection(group: NoteGroup) {
        
        context.delete(group)
        do {
            try context.save()
            fetchNotes()
            fetchSections()
        } catch {
            print("cannot delete item")
        }
    }

    func refresh() {
        fetchNotes()
        fetchSections()
        delegate?.refresh()
    }
    
    func updateNote(newBody: String, id: String, newDate: Date, newFont: String,
                    fontSize: Int, fontColor: UIColor, backgroundColor: UIColor) {

        guard let groupURL = URL(string: id) else { return }
        guard let convertedGroupID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: groupURL) else { return }
        
        do {
            let note = try context.existingObject(with: convertedGroupID) as! Note
            note.body = newBody
            note.font = newFont
            note.fontSize = (fontSize) as NSNumber
            note.color = fontColor
            note.backgroundColor = backgroundColor
        } catch {
            print("oops")
        }
        
        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        fetchNotes()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }

    func fetchNotes() {

        let request = Note.fetchRequest()
        let sort1 = NSSortDescriptor(key: "date", ascending: false)
        guard let groupID = groupID else { return }

        let predicate = NSPredicate(format: "groupID = %@", groupID)
        request.predicate = predicate
        
        request.sortDescriptors = [sort1]
        
        do {
            notes = try context.fetch(request)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Load Notes",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
        
    }
    
    func fetchSections() {
        let request = NoteGroup.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        
        do {
            groups = try context.fetch(request)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Load Sections",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalHeight(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalWidth(0.45))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        group.interItemSpacing = .fixed(20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        section.boundarySupplementaryItems = [header]
        
        return UICollectionViewCompositionalLayout(section: section)
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
     
        let searchBar = searchController.searchBar
        if let filterText = searchBar.text {
            filterNotesForSearchText(filterText)
        }
        
    }
    
    func filterNotesForSearchText(_ searchText: String) {
        
        if searchText != "" {
            filteredNotes = notes.filter { (note: Note) -> Bool in
                return note.body?.lowercased().contains(searchText.lowercased()) ?? false
            }
            fetchNotes()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        } else {
            fetchNotes()
            fetchSections()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newNoteViewController = segue.destination as? NewNoteViewController {
             newNoteViewController.delegate = self
        }
        if let editNoteViewController = segue.destination as? EditNoteViewController {
            editNoteViewController.delegate = self
        }
    }
    
    @IBSegueAction func createNewNotePressed(_ coder: NSCoder, sender: Any?, segueIdentifier: String?) -> NewNoteViewController? {
        
        editSwitch = false
        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        guard let groupID = groupID else { return nil }
        let newNoteVC = NewNoteViewController(coder: coder, groupID: groupID)
        return newNoteVC
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchController.isActive = false
    }
    
    @IBSegueAction func editNoteSegue(_ coder: NSCoder, sender: UICollectionViewCell?,
                                      segueIdentifier: String?) -> EditNoteViewController? {
        
        editSwitch = false
        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        guard let cell = sender,
              let indexPath = collectionView.indexPath(for: cell) else { return nil }
        
        if isFiltering {
            
            if let body = filteredNotes[indexPath.row].body,
               let date = filteredNotes[indexPath.row].date,
               let font = filteredNotes[indexPath.row].font,
//               let noteID = filteredNotes[indexPath.row].objectID,
               let fontSize = filteredNotes[indexPath.row].fontSize?.intValue,
               let fontColor = filteredNotes[indexPath.row].color,
               let backgroundColor = filteredNotes[indexPath.row].backgroundColor {
                let editNoteVC = EditNoteViewController(coder: coder, body: body,
                                                        id: filteredNotes[indexPath.row].objectID.uriRepresentation().absoluteString, date: date,
                                                        font: font, fontSize: fontSize,
                                                        fontColor: fontColor, backgroundColor: backgroundColor)
                return editNoteVC
            }         else {
                print("can't load existing note")
                return EditNoteViewController(coder: coder, body: "", id: filteredNotes[indexPath.row].objectID.uriRepresentation().absoluteString,
                                              date: Date(), font: "Arial", fontSize: 18, fontColor: .label,
                                              backgroundColor: .secondarySystemBackground)
            }
            
        } else {
            
            if let body = notes[indexPath.row].body,
               let date = notes[indexPath.row].date,
               let font = notes[indexPath.row].font,
               let fontSize = notes[indexPath.row].fontSize?.intValue,
               let fontColor = notes[indexPath.row].color,
               let backgroundColor = notes[indexPath.row].backgroundColor {
                let editNoteVC = EditNoteViewController(coder: coder, body: body, id: notes[indexPath.row].objectID.uriRepresentation().absoluteString,
                                                        date: date, font: font, fontSize: fontSize,
                                                        fontColor: fontColor, backgroundColor: backgroundColor)
                return editNoteVC
            }         else {
                print("can't load existing note")
                return EditNoteViewController(coder: coder, body: "", id: filteredNotes[indexPath.row].objectID.uriRepresentation().absoluteString,
                                              date: Date(), font: "Arial", fontSize: 18, fontColor: .label,
                                              backgroundColor: .secondarySystemBackground)
            }
        }
    }
        
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if isFiltering {
            return filteredNotes.count
        } else {
            return notes.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! NoteCollectionViewCell
        if isFiltering {
            
            cell.body.text = filteredNotes[indexPath.row].body
            if let font = filteredNotes[indexPath.row].font,
               let fontColor = filteredNotes[indexPath.row].color,
               let backgroundColor = filteredNotes[indexPath.row].backgroundColor  {
                cell.body.font = UIFont(name: font, size: 16)
                cell.body.textColor = fontColor
                cell.contentView.backgroundColor = backgroundColor
            }
            
        } else {
            
            cell.body.text = notes[indexPath.row].body
            if let font = notes[indexPath.row].font,
               let fontColor = notes[indexPath.row].color,
               let backgroundColor = notes[indexPath.row].backgroundColor  {
                cell.body.font = UIFont(name: font, size: 16)
                cell.body.textColor = fontColor
                cell.contentView.backgroundColor = backgroundColor
            }

        }
        
        cell.contentView.layer.cornerRadius = 8
        cell.layer.cornerRadius = 8
        cell.layer.shadowRadius = 3
        cell.layer.shadowColor = UIColor.systemGray3.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowOpacity = 1
        cell.layer.masksToBounds = false
        
        cell.deleteButton.tag = indexPath.row
        
        if editSwitch == false {
            cell.deleteButton.isHidden = true
            
            let layer: CALayer = cell.layer
            layer.removeAnimation(forKey: "shaking")
        } else {
            cell.deleteButton.isHidden = false
            
            let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
            shakeAnimation.duration = 0.05
            shakeAnimation.repeatCount = 2
            shakeAnimation.autoreverses = true
            let startAngle: Float = (-2) * 3.14159/180
            let stopAngle = -startAngle
            shakeAnimation.fromValue = NSNumber(value: startAngle as Float)
            shakeAnimation.toValue = NSNumber(value: 3 * stopAngle as Float)
            shakeAnimation.autoreverses = true
            shakeAnimation.duration = 0.15
            shakeAnimation.repeatCount = 10000
            shakeAnimation.timeOffset = 290 * drand48()
            
            let layer: CALayer = cell.layer
            layer.add(shakeAnimation, forKey:"shaking")
        }
        
        return cell
    }
}
