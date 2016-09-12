//
//  CustomMemberCell.swift
//  ValleybrookMessenger
//
//  Created by Adam Zarn on 9/9/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class CustomMemberCell: UITableViewCell {
    
    let ref = FIRDatabase.database().reference()
    
    @IBOutlet weak var myImageView: UIImageView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    func setCell(imageName: String, name: String, email: String, phone: String) {
        self.myImageView.image = UIImage(named: imageName)
        self.nameLabel.text = name
        self.emailLabel.text = email
        self.phoneLabel.text = FirebaseClient.sharedInstance.formatPhoneNumber(phone)
        
    }
}

