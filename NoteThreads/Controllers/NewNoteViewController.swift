//
//  NewNoteViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/29/22.
//

import UIKit

protocol NewNoteViewControllerDelegate: AnyObject {
    func refresh()
}

class NewNoteViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let sectionIndex: Int32?
    
    @IBOutlet weak var noteBody: UITextView!
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: NewNoteViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init?(coder: NSCoder, index: Int32) {
        self.sectionIndex = index
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        if let body = noteBody.text {
            saveNote(body: body)
        }
        dismiss(animated: true)
    }
    
    func saveNote(body: String) {
        
        let newNote = Note(context: context)
        newNote.body = body
        newNote.date = Date()
        newNote.noteIndex = sectionIndex as NSNumber?
        
        print(newNote.noteIndex, "new note index")
        do {
            try context.save()
            delegate?.refresh()
        } catch {
            let alert = UIAlertController(title: "Error",
                                          message: "Could Not Save Note",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
            
        }
    }
}
