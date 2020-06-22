//
//  ResidentManager.swift
//  AAT Genie Remote
//
//  Created by John Charlton on 2020-06-21.
//  Copyright © 2020 stevorama.com. All rights reserved.
//

import Foundation
import Promises

class ResidentManager {
    static let sharedInsatance = ResidentManager()
    let userDefaults = UserDefaults.standard
    
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
    
    func getActiveName() -> String? {
        guard let activeResidentId = self.userDefaults.object(forKey: "ActiveResidentId") as? Int else { return nil }
        
        guard let resident = get(id: activeResidentId) else { return nil }
        guard let name = resident.name else { return nil }
        return name
    }
    
    func getActivePicture() -> String? {
        guard let activeResidentId = self.userDefaults.object(forKey: "ActiveResidentId") as? Int else { return nil }
        
        guard let resident = get(id: activeResidentId) else { return nil }
        guard let picture = resident.pictureBase64 else { return nil }
        return picture
    }
    
    private func get(id: Int) -> Resident? {
        var resident: Resident?
        do {
            if let resData = self.userDefaults.object(forKey: "Residents") as? Data {
                let residents = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(resData as Data) as? [ResidentManager.Resident]
                guard let residentArray = residents else { fatalError("No residents found") }
                
                guard let residentResult = residentArray.first(where: { $0.id == id }) else { fatalError("No resident found for id: \(id)") }
                resident = residentResult
            }
        }
        catch {
           print("Error getting resident: \(error)")
        }
        return resident
    }
    
    // retrieve and store assigned resident extended data
    func store(residentIds: [Int]) -> Promise <Bool> {
        struct ResidentsResult: Codable {
            let errorMessage: String?
            let errorSeverity: Int?
            let residents: [ResidentSingle]
        }
        
        struct ResidentSingle: Codable {
            let id: Int
            let facilityId: Int
            let name: String
            let pictureBase64: String?
        }
        
        guard let clientInfo = plistValues(bundle: Bundle.main) else { fatalError("Auth0 client info is missing") }
        return Promise<Bool>(on: .global(qos: .background)) { (fullfill, reject) in
            guard let accessToken = SessionManager.shared.credentials?.accessToken else {
                //TODO: throw exception
                return
            }
            
            let url = URL(string: clientInfo.audience + "/api/residents/list")!
            var request = URLRequest(url: url)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            var httpBody: Data
            do {
                let residentsJSON = try JSONEncoder().encode(residentIds)
                guard let ids = String(data: residentsJSON, encoding: .utf8) else { fatalError() }
                guard let idsData = ids.data(using: String.Encoding.utf8) else { fatalError() }
                httpBody = idsData
            }
            catch {
                print("Error getting residents: \(error.localizedDescription)")
                fatalError("Error getting residents: \(error.localizedDescription)")
            }
            
            request.httpBody = httpBody
            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error {
                    print("Error getting residents: \(error)")
                }
                
                guard let response = response as? HTTPURLResponse else {
                    fatalError("Invalid HTTP response")
                }
                
                let statusCode = response.statusCode as Int
                guard statusCode == 200 else {
                    print("Status code: \(statusCode)")
                    fatalError("Invalid HTTP status code: \(statusCode)")
                }
                
                guard let data = data else {
                    fatalError("No HTTP data")
                }
                
                do {
                    let residentsResult = try JSONDecoder().decode(ResidentsResult.self, from: data)
                    let residents = residentsResult.residents

                    var residentArray: [ResidentManager.Resident] = []
                    for r in residents {
                        let resident = ResidentManager.Resident(id: r.id, facilityId: r.facilityId, name: r.name, pictureBase64: r.pictureBase64)
                        residentArray.append(resident)
                    }
                    let residentsData = try NSKeyedArchiver.archivedData(withRootObject: residentArray, requiringSecureCoding: false)
                    self.userDefaults.set(residentsData, forKey: "Residents")
                    fullfill(true)
                }
                catch {
                    print(error.localizedDescription)
                    reject(error)
                }
            }
            task.resume()
        }
    }
}
