//
//  SignInViewController.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-19.
//  Copyright © 2020 stevorama.com. All rights reserved.
//S

import UIKit
import Auth0
import SimpleKeychain
import Promises

class SignInViewController: UIViewController {

    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func showLoginController(_ sender: UIButton) {
        SessionManager.shared.patchMode = false
        self.checkToken() {
            self.showLogin()
        }
    }

    fileprivate func showLogin() {
        guard let clientInfo = plistValues(bundle: Bundle.main) else { return }
        SessionManager.shared.patchMode = false
        Auth0
            .webAuth()
            .scope("openid profile email offline_access")
            .audience(clientInfo.audience)
            .start {
                switch $0 {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let credentials):
                    if(!SessionManager.shared.store(credentials: credentials)) {
                        print("Failed to store credentials")
                    } else {
                        SessionManager.shared.retrieveProfile { error in
                            DispatchQueue.main.async {
                                guard error == nil else {
                                    print("Failed to retrieve profile: \(String(describing: error))")
                                    return self.showLogin()
                                }
                                guard let profile = SessionManager.shared.profile else { fatalError("Missing profile") }
                                guard let claims = profile.customClaims else { fatalError("Missing profile") }
                                guard let userMetadata = claims[clientInfo.userMetadata] as? NSDictionary else { fatalError("Unable to retrieve user metadata") }
                                
                                // cache the user's picture in local storage
                                let picture = userMetadata["picture"] as? String
                                self.userDefaults.set(picture, forKey: "Picture")

                                // cache the defaultResidentId in local storage
                                let defaultResidentId = userMetadata["defaultResidentId"] as? Int ?? -1
                                self.userDefaults.set(defaultResidentId, forKey: "DefaultResidentId")
                                
                                // cache the activeResidentId in local storage
                                self.userDefaults.set(defaultResidentId, forKey: "ActiveResidentId")
                                
                                // assemble the user's assigned residentIds
                                guard let appMetadata = claims[clientInfo.appMetadata] as? NSDictionary else { fatalError("Unable to retrieve app metadata") }
                                guard let residentIds = appMetadata["residentIds"] as? [Int] else { fatalError("Unable to retrieve residentIds") }
                                
                                // retrieve extended resident properties and cache in local storage
                                let manager = ResidentManager()
                                manager.store(residentIds: residentIds).then { (result) in
                                    if result {
                                        // should be good to go from here
                                        self.performSegue(withIdentifier: "ShowProfileNonAnimated", sender: nil)
                                    }
                                }.catch { (error) in
                                    fatalError("Error retrieving extended profile metadata: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
        }
    }

    fileprivate func checkToken(callback: @escaping () -> Void) {
        let loadingAlert = UIAlertController.loadingAlert()
        loadingAlert.presentInViewController(self)
        SessionManager.shared.renewAuth { error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    guard error == nil else {
                        print("Failed to retrieve credentials: \(String(describing: error))")
                        return callback()
                    }
                    SessionManager.shared.retrieveProfile { error in
                        DispatchQueue.main.async {
                            guard error == nil else {
                                print("Failed to retrieve profile: \(String(describing: error))")
                                return callback()
                            }
                            self.performSegue(withIdentifier: "ShowProfileNonAnimated", sender: nil)
                        }
                    }
                }
            }
        }
    }
}
