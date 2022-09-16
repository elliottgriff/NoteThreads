//
//  ViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/24/22.
//

import UIKit

protocol NoteCellDelegate: UICollectionViewCell {
    func toggle()
}

protocol NotesCollectionViewControllerDelegate: AnyObject {
    func refresh()
}

class NotesCollectionViewController: UICollectionViewController, NewNoteViewControllerDelegate, EditNoteDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private let reuseIdentifier = "NoteCell"
    private let newNoteSegue = "NewNote"
    
    private var notes = [Note]()
    private var groups = [NoteGroup]()
    
    var editSwitch = false
    var groupInt: Int?
    
    weak var cellDelegate: NoteCellDelegate?
    weak var delegate: NotesCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        collectionView.dragInteractionEnabled = true
        
        collectionView.register(HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier)
        
        fetchSections()
        fetchNotes()
        
        if let groupInt = groupInt {
            title = groups[groupInt].title
        }
        
    }
    
    init?(coder: NSCoder, groupInt: Int) {
        self.groupInt = groupInt
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
    
    func updateNote(newBody: String, index: Int, newDate: Date, newFont: String, fontSize: Int, fontColor: UIColor, backgroundColor: UIColor) {
        
        notes[index].body = newBody
        notes[index].date = newDate
        notes[index].font = newFont
        notes[index].fontSize = fontSize as NSNumber
        notes[index].color = fontColor
        notes[index].backgroundColor = backgroundColor
        
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
    
    func fetchNotes() {
        
        let request = Note.fetchRequest()
        let sort1 = NSSortDescriptor(key: "date", ascending: false)
        guard let groupInt = groupInt else {
            return
        }

        if let filter = groups[groupInt].title {
            let predicate = NSPredicate(format: "group = %@", filter)
            request.predicate = predicate
        }
        
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
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
        
        guard let groupInt = groupInt else {
            return nil
        }

        if let groupTitle = groups[groupInt].title {
            let newNoteVC = NewNoteViewController(coder: coder, group: groupTitle)
            return newNoteVC
        }
        
        return NewNoteViewController(coder: coder, group: "fuck")
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
        
        if let body = notes[indexPath.row].body,
           let date = notes[indexPath.row].date,
            let font = notes[indexPath.row].font,
           let fontSize = notes[indexPath.row].fontSize?.intValue,
            let fontColor = notes[indexPath.row].color,
           let backgroundColor = notes[indexPath.row].backgroundColor {
            let editNoteVC = EditNoteViewController(coder: coder, body: body,
                                                    index: indexPath.row, date: date,
                                                    font: font, fontSize: fontSize,
                                                    fontColor: fontColor, backgroundColor: backgroundColor)
            return editNoteVC
        } else {
            print("can't load existing note")
            return EditNoteViewController(coder: coder, body: "",
                                          index: indexPath.row, date: Date(),
                                          font: "Arial", fontSize: 18, fontColor: .label,
                                          backgroundColor: .secondarySystemBackground)
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! NoteCollectionViewCell
        
        cell.body.text = notes[indexPath.row].body
        if let font = notes[indexPath.row].font,
            let fontColor = notes[indexPath.row].color,
           let backgroundColor = notes[indexPath.row].backgroundColor  {
            cell.body.font = UIFont(name: font, size: 16)
            cell.body.textColor = fontColor
            cell.contentView.backgroundColor = backgroundColor
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
