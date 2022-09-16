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

class NewNoteViewController: UIViewController, UIFontPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIColorPickerViewControllerDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let colorPicker = UIColorPickerViewController()
    
    @IBOutlet weak var fontSizePicker: UIPickerView!
    
    var fontSizePickerOptions = Array(12...50)
    
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
        fontSize = 18
        fontColor = .label
        backgroundColor = .secondarySystemBackground
        if let size = fontSize, let name = noteFont {
            setFont(size: size, name: name, color: .label)
        }
        fontSizePicker.delegate = self
        fontSizePicker.dataSource = self
        colorPicker.delegate = self
    }
    
    func setFont(size: Int, name: String, color: UIColor) {
        noteBody.font = (UIFont(name: name, size: CGFloat(size)))
        noteBody.textColor = color
        noteBody.setNeedsLayout()
    }
    
    @IBAction func fontSizePressed(_ sender: Any) {
        fontSizePicker.isHidden = false
    }
    
    @IBAction func fontStylePressed(_ sender: Any) {
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fontSizePickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let rowTitle = "\(fontSizePickerOptions[row])"
        return rowTitle
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        fontSize = row + 1
        if let size = fontSize, let name = noteFont, let color = fontColor {
            setFont(size: size, name: name, color: color)
        }
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
