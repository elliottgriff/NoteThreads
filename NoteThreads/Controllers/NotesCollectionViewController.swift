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

class NotesCollectionViewController: UICollectionViewController, NewNoteViewControllerDelegate, EditNoteDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private let reuseIdentifier = "NoteCell"
    private let newNoteSegue = "NewNote"
    
    private var notes = [Note]()
    
    var editSwitch = false
    
    weak var delegate: NoteCellDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "NoteStrings"
        
        setupPressGesture()
//        setupLongPressGestures()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        collectionView.dragInteractionEnabled = true
        
        fetchNotes()
        
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
//        guard let indexPath = collectionView.indexPathForItem(at: sender.superview!.center) else { return }

        let note = notes[sender.tag]
        print(sender.tag)
        let alert = UIAlertController(title: "Delete Note?",
                                      message: note.body,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
            self.deleteItem(item: note)
        }))
        present(alert, animated: true)
        
    }
//
//    func setupLongPressGestures() {
//        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
//        longPressGesture.minimumPressDuration = 1.0
//        longPressGesture.delegate = self
//
//        self.collectionView.addGestureRecognizer(longPressGesture)
//    }

//    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
//        if gestureRecognizer.state == .began {
//            let touchPoint = gestureRecognizer.location(in: self.collectionView)
//            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
//                let item = notes[indexPath.row]
//                let cell = collectionView.cellForItem(at: indexPath)
//                let alert = UIAlertController(title: "Delete Note?",
//                                              message: notes[indexPath.row].body,
//                                              preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//                alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
//                    self.deleteItem(item: item)
//                }))
//                present(alert, animated: true)
//            }
//        }
//    }
        

    func setupPressGesture() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDragPress(_:)))
        collectionView.addGestureRecognizer(gesture)
    }

    @objc func handleDragPress(_ gesture: UILongPressGestureRecognizer){
        
        guard let collectionView = collectionView else { return }
        
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
            
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
        
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
    
    func updateNote(newBody: String, index: Int, newDate: Date) {
        print(newBody, index, newDate)
        notes[index].body = newBody
        notes[index].date = newDate
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
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        
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
    
    @IBAction func newNotePressed(_ sender: UIBarButtonItem) {
        editSwitch = false
        do {
            try context.save()
        } catch {
            print("couldn't save context")
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        performSegue(withIdentifier: newNoteSegue, sender: self)
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
        
        if let body = notes[indexPath.row].body, let date = notes[indexPath.row].date {
            let NoteVC = EditNoteViewController(coder: coder, body: body, index: indexPath.row, date: date)
            return NoteVC
        } else {
            print("can't load existing note")
            return EditNoteViewController(coder: coder, body: "", index: indexPath.row, date: Date())
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! NoteCollectionViewCell
        
        cell.body.text = notes[indexPath.row].body
        
        cell.contentView.backgroundColor = .systemCyan
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

    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let item = notes.remove(at: sourceIndexPath.row)
        notes.insert(item, at: destinationIndexPath.row)

        do {
            try context.save()
        } catch {
            print("couldnt save new order")
        }
    }
    
}

extension UICollectionView {

  func indexPathForView(view: AnyObject) -> IndexPath? {
      guard let view = view as? UIView else { return nil }
      let senderIndexPath = self.convert(CGPoint.zero, from: view)
      return self.indexPathForItem(at: senderIndexPath)
  }

}
