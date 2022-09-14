//
//  NoteCollectionViewCell.swift
//  NoteThreads
//
//  Created by elliott on 8/25/22.
//

import UIKit

class NoteCollectionViewCell: UICollectionViewCell, NoteCellDelegate {
    
    func toggle() {
        print("toggle")
        if deleteButton.isHidden {
            deleteButton.isHidden = false
        } else {
            deleteButton.isHidden = true
        }
    }

    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    
}
