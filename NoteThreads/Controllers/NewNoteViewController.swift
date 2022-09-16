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

class NewNoteViewController: UIViewController, UIFontPickerViewControllerDelegate, UIColorPickerViewControllerDelegate, UITextViewDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let colorPicker = UIColorPickerViewController()
    
    @IBOutlet weak var fontSizePicker: UISlider!
    
    var fontSizePickerOptions = Array(20...50)
    
    @IBOutlet weak var noteBody: UITextView!
    private var noteFont: String?
    private var fontSize: Int?
    private var fontColor: UIColor?
    private var backgroundColor: UIColor?
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    private var groupString: String?
    
    weak var delegate: NewNoteViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteFont = "Arial"
        fontSize = 20
        fontColor = .label
        backgroundColor = .secondarySystemBackground
        if let size = fontSize, let name = noteFont {
            setFont(size: size, name: name, color: .label)
            fontSizePicker.setValue(Float(size), animated: true)
        }
        colorPicker.delegate = self
        noteBody.delegate = self
        hideKeyboard()
    }
    
    func hideKeyboard() {
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipe.direction = .down
        noteBody.addGestureRecognizer(swipe)
    }
    
    @objc func dismissKeyboard() {
        noteBody.endEditing(true)
    }
    
    func setFont(size: Int, name: String, color: UIColor) {
        noteBody.font = (UIFont(name: name, size: CGFloat(size)))
        noteBody.textColor = color
        noteBody.setNeedsLayout()
    }
    
    @IBAction func fontSizePressed(_ sender: Any) {
        if fontSizePicker.isHidden {
            fontSizePicker.isHidden = false
        } else {
            fontSizePicker.isHidden = true
        }
    }
    
    @IBAction func fontSizeSliderMoved(_ sender: Any) {
        fontSize = Int(fontSizePicker.value)
        if let noteFont = noteFont, let fontColor = fontColor {
            setFont(size: Int(fontSizePicker.value), name: noteFont, color: fontColor)
        }
    }
    
    
    @IBAction func fontStylePressed(_ sender: Any) {
        fontSizePicker.isHidden = true
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true
        let vc = UIFontPickerViewController(configuration: configuration)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func fontColorPressed(_ sender: Any) {
        fontSizePicker.isHidden = true
        colorPicker.title = "Font Color"
        present(colorPicker, animated: true)
    }
    
    @IBAction func backgroundColorPressed(_ sender: Any) {
        fontSizePicker.isHidden = true
        colorPicker.title = "Background Color"
        present(colorPicker, animated: true)
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        if let body = noteBody.text, let fontSize = fontSize {
            saveNote(body: body, size: fontSize)
        }
        dismiss(animated: true)
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        
        if viewController.title == "Font Color" {
            fontColor = color
            if let size = fontSize, let name = noteFont, let color = fontColor {
                setFont(size: size, name: name, color: color)
            }
        } else if viewController.title == "Background Color" {
            backgroundColor = color
            if let backgroundColor = backgroundColor {
                view.backgroundColor = backgroundColor
                view.setNeedsLayout()
            }
        }
        colorPicker.dismiss(animated: true)
    }

    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }

        if let fontSize = fontSize {
            let font = UIFont(descriptor: descriptor, size: CGFloat(fontSize))
            noteBody.font = font
            noteFont = font.fontName
        }
        
        self.dismiss(animated: true)
    }
    
    init?(coder: NSCoder, group: String) {
        self.groupString = group
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func saveNote(body: String, size: Int) {
        
        let newNote = Note(context: context)
        newNote.body = body
        newNote.date = Date()
        newNote.group = groupString
        newNote.font = noteFont
        newNote.fontSize = fontSize as NSNumber?
        newNote.color = fontColor
        newNote.backgroundColor = backgroundColor
        
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
