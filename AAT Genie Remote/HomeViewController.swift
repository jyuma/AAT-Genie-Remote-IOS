//
//  HomeViewController.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-19.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import UIKit
import Auth0

class HomeViewController: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var activeResidentLabel: UILabel!
    @IBOutlet weak var uploadMediaButton: UIButton!
    @IBOutlet weak var createMessageButton: UIButton!
    @IBOutlet weak var messagesInButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    let userDefaults = UserDefaults.standard
    
    var profile: UserInfo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profile = SessionManager.shared.profile
        let name = self.profile.nickname ?? "no  name"
        self.welcomeLabel.text = "Welcome, \(name)"
        
        DispatchQueue.main.async {
            let residentManager = ResidentManager()
            self.activeResidentLabel.text = residentManager.getActiveName()

            // assign the resident picture
            let residentPicture = residentManager.getActivePicture()
            let picture = residentPicture ?? nil
            if picture != nil, let decodedData = Data(base64Encoded: picture!) {
                let image = UIImage(data: decodedData)
                self.avatarImageView.image = image
            } else {
                self.avatarImageView.image = UIImage(named: "no_avatar")
            }
        }
    }

    @IBAction func logout(_ sender: UIBarButtonItem) {
        SessionManager.shared.logout { error in
            
            guard error == nil else {
                return print("Error revoking token: \(error!)")
            }
            
            DispatchQueue.main.async {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
