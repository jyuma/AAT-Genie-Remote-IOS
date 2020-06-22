//
//  SessionManager.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-19.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import Foundation
import SimpleKeychain
import Auth0

class SessionManager {
    static let shared = SessionManager()
    private let authentication = Auth0.authentication()
    let credentialsManager: CredentialsManager!
    var profile: UserInfo?
    var credentials: Credentials?
    var patchMode: Bool = false

    private init () {
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication())
         _ = self.authentication.logging(enabled: true) // API Logging
    }

    func retrieveProfile(_ callback: @escaping (Error?) -> ()) {
        guard let accessToken = self.credentials?.accessToken
            else { return callback(CredentialsManagerError.noCredentials) }
        self.authentication
            .userInfo(withAccessToken: accessToken)
            .start { result in
                switch(result) {
                case .success(let profile):
                    self.profile = profile
                    callback(nil)
                case .failure(let error):
                    callback(error)
                }
        }
    }

    func renewAuth(_ callback: @escaping (Error?) -> ()) {
        // Check it is possible to return credentials before asking for Touch
        guard self.credentialsManager.hasValid() else {
            return callback(CredentialsManagerError.noCredentials)
        }
        self.credentialsManager.credentials { error, credentials in
            guard error == nil, let credentials = credentials else {
                return callback(error)
            }
            self.credentials = credentials
            callback(nil)
        }
    }

    func logout(_ callback: @escaping (Error?) -> Void) {
        // Remove credentials from KeyChain
        self.credentials = nil
        self.credentialsManager.revoke(callback)
    }

    func store(credentials: Credentials) -> Bool {
        self.credentials = credentials
        // Store credentials in KeyChain
        return self.credentialsManager.store(credentials: credentials)
    }
}

func plistValues(bundle: Bundle) -> (clientId: String, domain: String, audience: String, managementAudience: String,
    userMetadata: String, appMetadata: String)? {
    guard
        let path = bundle.path(forResource: "Auth0", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
    }

    guard
        let clientId = values["ClientId"] as? String,
        let domain = values["Domain"] as? String,
        let audience = values["Audience"] as? String,
        let managementAudience = values["ManagementAudience"] as? String,
        let userMetadata = values["UserMetadata"] as? String,
        let appMetadata = values["AppMetadata"] as? String
    
        else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
    }
    return (clientId: clientId, domain: domain, audience: audience, managementAudience: managementAudience, userMetadata: userMetadata, appMetadata: appMetadata)
}
