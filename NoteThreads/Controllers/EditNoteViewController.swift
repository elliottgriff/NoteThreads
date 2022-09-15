//
//  EditNoteViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/31/22.
//

import UIKit

protocol EditNoteDelegate: AnyObject {
    func updateNote(newBody: String, index: Int, newDate: Date, newFont: String)
}

class EditNoteViewController: UIViewController, UIFontPickerViewControllerDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
//    private var notes = [Note]()
    
    let bodyString: String?
    let noteIndex: Int?
    let noteDate: Date?
    var noteFont: String?
    var fontSize: Int?
    var fontColor: UIColor?
    var backgroundColor: UIColor?
    
    @IBOutlet weak var noteBody: UITextView!
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    
    weak var delegate: EditNoteDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        noteBody.text = bodyString
        if let noteFont = noteFont, let fontSize = fontSize {
            noteBody.font = UIFont(name: noteFont, size: CGFloat(fontSize))
        }
        noteBody.textColor = fontColor
        view.backgroundColor = backgroundColor

    }
    
    init?(coder: NSCoder, body: String, index: Int,
          date: Date, font: String, fontSize: Int,
          fontColor: UIColor, backgroundColor: UIColor) {
        
        self.bodyString = body
        self.noteIndex = index
        self.noteDate = date
        self.noteFont = font
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        
        super.init(coder: coder)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func fontSizePressed(_ sender: Any) {
        
    }
    
    @IBAction func fontStylePressed(_ sender: Any) {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true
        let vc = UIFontPickerViewController(configuration: configuration)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func fontColorPressed(_ sender: Any) {
    }
    
    @IBAction func backgroundColorPressed(_ sender: Any) {
    }
    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }

        let font = UIFont(descriptor: descriptor, size: 18)
        noteBody.font = font
        noteFont = font.fontName
        self.dismiss(animated: true)
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        
        if let body = noteBody.text, let index = noteIndex, let font = noteFont {
            delegate?.updateNote(newBody: body, index: index, newDate: Date(), newFont: font)
        }
        dismiss(animated: true)
    }


}
