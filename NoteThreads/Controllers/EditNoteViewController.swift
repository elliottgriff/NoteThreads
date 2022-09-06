//
//  EditNoteViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/31/22.
//

import UIKit

protocol EditNoteDelegate: AnyObject {
    func updateNote(newBody: String, index: Int, newDate: Date)
}

class EditNoteViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
//    private var notes = [Note]()
    
    let bodyString: String?
    let noteIndex: Int?
    let noteDate: Date?
    
    @IBOutlet weak var noteBody: UITextView!
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    weak var delegate: EditNoteDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        noteBody.text = bodyString

    }
    
    init?(coder: NSCoder, body: String, index: Int, date: Date) {
        
        self.bodyString = body
        self.noteIndex = index
        self.noteDate = date
        
        super.init(coder: coder)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        
        if let body = noteBody.text, let index = noteIndex {
            delegate?.updateNote(newBody: body, index: index, newDate: Date())
        }
        dismiss(animated: true)
    }


}
