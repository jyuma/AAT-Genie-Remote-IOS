//
//  ResidentModel.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-21.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import Foundation
class ResidentManager {
    static let sharedInsatance = ResidentManager()
    
    @objc(Resident)class Resident: NSObject, NSCoding {
        let id: Int?
        let facilityId: Int?
        let name: String?
        let pictureBase64: String?
        
        func encode(with coder: NSCoder) {
            coder.encode(id, forKey: "id")
            coder.encode(facilityId, forKey: "facilityId")
            coder.encode(name, forKey: "name")
            coder.encode(pictureBase64, forKey: "pictureBase64")
        }
        
        required init?(coder: NSCoder) {
            self.id = coder.decodeObject(forKey: "id") as? Int
            self.facilityId = coder.decodeObject(forKey: "facilityId") as? Int
            self.name = coder.decodeObject(forKey: "name") as? String
            self.pictureBase64 = coder.decodeObject(forKey: "pictureBase64") as? String
        }
        
        init(id: Int, facilityId: Int, name: String, pictureBase64: String?) {
            self.id = id
            self.facilityId = facilityId
            self.name = name
            self.pictureBase64 = pictureBase64
        }
    }
}

