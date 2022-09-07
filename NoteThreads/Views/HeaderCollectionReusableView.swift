//
//  HeaderCollectionReusableView.swift
//  NoteThreads
//
//  Created by elliott on 9/6/22.
//

import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {
    
    static let identifier = "HeaderIdentifier"
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var headerNewNoteButton: UIButton!
    
}
