//
//  CoreDataStack+HistoryTracker.swift
//  FNote
//
//  Created by Dara Beng on 10/25/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import CoreData


class CoreDataStackHistoryTracker {
    
    /// The key for the token value stored in `UserDefaults`.
    let historyTokenDataKey: String

    /// The last history token stored in `UserDefaults`.
    private(set) lazy var lastToken: NSPersistentHistoryToken? = {
        guard let tokenData = UserDefaults.standard.data(forKey: historyTokenDataKey) else { return nil }
        let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
        return token
    }()
    
    
    /// Create a history tracker object with a key.
    /// - Parameter historyTokenDataKey: The key for the token value stored in `UserDefaults`.
    init(historyTokenDataKey: String) {
        self.historyTokenDataKey = historyTokenDataKey
    }
    
    
    /// Assign the given token to `lastToken`.
    ///
    /// The method also converts and stores the token as `Data` in `UserDefaults`.
    /// - Parameter token: The token to set.
    func updateLastToken(_ token: NSPersistentHistoryToken) {
        do {
            let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            UserDefaults.standard.setValue(tokenData, forKey: historyTokenDataKey)
            lastToken = token
        } catch {
            print("🧨 cannot archive Persistent History Token 💣")
        }
    }
    
    /// Get history change token from the notification.
    /// - Parameter notification: The persistent store remote change notification.
    /// - Returns: The token or `nil` if cannot get the token.
    func token(fromRemoteChange notification: Notification) -> NSPersistentHistoryToken? {
        guard let changeInfo = notification.userInfo else { return nil }
        guard let token = changeInfo["historyToken"] else { return nil }
        return token as? NSPersistentHistoryToken
    }
}
