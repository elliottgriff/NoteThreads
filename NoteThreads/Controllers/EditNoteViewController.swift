//
//  EditNoteViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/31/22.
//

import UIKit

class EditNoteViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var notes = [Note]()
    
    let titleString: String?
    let bodyString: String?
    let noteIndex: Int?
    
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteBody: UITextView!
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    weak var delegate: NewNoteViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        noteTitle.text = titleString
        noteBody.text = bodyString
        
        fetchNotes()

    }
    
    init?(coder: NSCoder, title: String, body: String, index: Int) {
        
        self.titleString = title
        self.bodyString = body
        self.noteIndex = index
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        
        print(notes.count)
        
        if let index = noteIndex, let title = noteTitle.text, let body = noteBody.text {
            updateNote(note: notes[index], newTitle: title, newBody: body)
        }
        dismiss(animated: true)
    }
    
    func fetchNotes() {
        
        do {
            notes = try context.fetch(Note.fetchRequest())
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Load Notes",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
        
    }
    
    func updateNote(note: Note, newTitle: String, newBody: String) {
        
        note.title = newTitle
        note.body = newBody
        
        do {
            try context.save()
            delegate?.refresh()
        } catch {
            print("cannot update item")
        }
    }

}
