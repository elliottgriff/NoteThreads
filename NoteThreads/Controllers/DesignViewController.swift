//
//  DesignViewController.swift
//  NoteThreads
//
//  Created by elliott on 9/15/22.
//

import UIKit

class DesignViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Design Note"
        view.backgroundColor = .clear
        createTheView()
    }

    private func createTheView() {

        let xCoord = self.view.bounds.width / 10
        let yCoord = self.view.bounds.height / 14

        let centeredView = UIView(frame: CGRect(x: xCoord, y: yCoord, width: self.view.frame.width * 0.8, height: self.view.frame.height * 0.75))
        centeredView.backgroundColor = .lightGray
        centeredView.layer.cornerRadius = 10
        self.view.addSubview(centeredView)
        
    }
}
