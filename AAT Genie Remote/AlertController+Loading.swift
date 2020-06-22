//
//  AlertController+Loading.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-19.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    static func loadingAlert() -> UIAlertController {
        return UIAlertController(title: "Loading", message: "Please, wait...", preferredStyle: .alert)
    }
    
    func presentInViewController(_ viewController: UIViewController) {
        viewController.present(self, animated: true, completion: nil)
    }

    static func alertWithTitle(_ title: String? = nil, message: String? = nil, includeDoneButton: Bool = false) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if includeDoneButton {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        return alert
    }

}
