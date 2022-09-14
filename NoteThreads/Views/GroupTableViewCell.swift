//
//  SectionTableViewCell.swift
//  NoteThreads
//
//  Created by elliott on 9/13/22.
//

import UIKit

class GroupTableViewCell: UITableViewCell {

    @IBOutlet weak var body: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configureCell(with data: String) {
        body.text = data
    }

}
