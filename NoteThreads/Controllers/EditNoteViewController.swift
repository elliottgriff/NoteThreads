//
//  EditNoteViewController.swift
//  NoteThreads
//
//  Created by elliott on 8/31/22.
//

import UIKit

protocol EditNoteDelegate: AnyObject {
    func updateNote(newBody: String, index: Int, newDate: Date,
                    newFont: String, fontSize: Int, fontColor: UIColor, backgroundColor: UIColor)
}

class EditNoteViewController: UIViewController, UIFontPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIColorPickerViewControllerDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
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
    
    @IBOutlet weak var fontSizePicker: UIPickerView!
    
    let colorPicker = UIColorPickerViewController()
    
    weak var delegate: EditNoteDelegate?
    
    var fontSizePickerOptions = Array(12...50)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.title = "TEST"
        
        noteBody.text = bodyString
        noteBody.textColor = fontColor
        
        view.backgroundColor = backgroundColor
        fontSizePicker.delegate = self
        fontSizePicker.dataSource = self
        colorPicker.delegate = self
        
        if let noteFont = noteFont, let fontSize = fontSize, let fontColor = fontColor {
            setFont(size: fontSize, name: noteFont, color: fontColor)
        }
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
    
    func setFont(size: Int, name: String, color: UIColor) {
        noteBody.font = (UIFont(name: name, size: CGFloat(size)))
        noteBody.textColor = color
        noteBody.setNeedsLayout()
    }
    
    @IBAction func fontSizePressed(_ sender: Any) {
        fontSizePicker.isHidden = false
        if let fontSize = fontSize {
            self.fontSizePicker.selectRow(fontSize - 12, inComponent: 0, animated: false)
        }
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
    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        if let fontSize = fontSize {
            let font = UIFont(descriptor: descriptor, size: CGFloat(fontSize))
            noteBody.font = font
            noteFont = font.fontName
            self.view.setNeedsLayout()
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func discardButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        
        if let body = noteBody.text, let index = noteIndex,
            let font = noteFont, let size = fontSize,
            let color = fontColor, let backgroundColor = backgroundColor {

            delegate?.updateNote(newBody: body, index: index, newDate: Date(),
                                 newFont: font, fontSize: size, fontColor: color,
                                 backgroundColor: backgroundColor)
            
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
        fontSizePickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let rowTitle = "\(fontSizePickerOptions[row])"
        return rowTitle
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        fontSize = row + 12
        if let size = fontSize, let name = noteFont, let color = fontColor {
            setFont(size: size, name: name, color: color)
        }
    }
}
