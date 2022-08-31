//
//  ViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/24/22.
//

import UIKit

class NotesCollectionViewController: UICollectionViewController, NewNoteViewControllerDelegate, UIGestureRecognizerDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private let reuseIdentifier = "NoteCell"
    private let newNoteSegue = "NewNote"
    
    private var notes = [Note]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        title = "NoteStrings"
        
        setupPressGesture()
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        fetchNotes()
        
    }

    func deleteItem(item: Note) {
        
        context.delete(item)
        
        do {
            try context.save()
            fetchNotes()
        } catch {
            print("cannot delete item")
        }
    }

    func refresh() {
        print("delegate")
        fetchNotes()
    }
    
    func fetchNotes() {
        
        do {
            notes = try context.fetch(Note.fetchRequest())
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
    
    
    @IBAction func newNotePressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: newNoteSegue, sender: self)
    }
    
    @IBSegueAction func editNoteSegue(_ coder: NSCoder, sender: UICollectionViewCell?,
                                      segueIdentifier: String?) -> EditNoteViewController? {
        
        print( "testing")
        guard let cell = sender,
              let indexPath = collectionView.indexPath(for: cell) else { return nil }
        
        if let title = notes[indexPath.row].title, let body = notes[indexPath.row].body {
            let NoteVC = EditNoteViewController(coder: coder, title: title, body: body, index: indexPath.row)
            print(indexPath.row, "index")
            return NoteVC
        } else {
            print("can't load existing note")
            return EditNoteViewController(coder: coder, title: "", body: "", index: -1)
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! NoteCollectionViewCell
        
        cell.title.text = notes[indexPath.row].title
        cell.body.text = notes[indexPath.row].body
        
        cell.contentView.backgroundColor = .systemCyan
        cell.contentView.layer.cornerRadius = 8
        cell.layer.cornerRadius = 8
        cell.layer.shadowRadius = 3
        cell.layer.shadowColor = UIColor.systemGray3.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowOpacity = 1
        cell.layer.masksToBounds = false
        
        return cell
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = .systemMint
        let seconds = 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            cell?.contentView.backgroundColor = .systemCyan
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = .systemCyan
        
    }
    
    func setupPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 1.0
        longPressGesture.delegate = self
        
        self.collectionView.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                let item = notes[indexPath.row]
                let cell = collectionView.cellForItem(at: indexPath)
                cell?.contentView.backgroundColor = .systemMint
                let seconds = 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    cell?.contentView.backgroundColor = .systemCyan
                }
                let alert = UIAlertController(title: "Delete Note?",
                                              message: notes[indexPath.row].title,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                    self.deleteItem(item: item)
                }))
                present(alert, animated: true)
            }
        }
    }
    
}
