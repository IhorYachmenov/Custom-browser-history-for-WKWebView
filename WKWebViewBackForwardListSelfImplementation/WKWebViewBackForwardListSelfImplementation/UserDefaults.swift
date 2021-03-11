//
//  UserDefaults.swift
//  WKWebViewBackForwardListSelfImplementation
//
//  Created by iOS on 08.03.2021.
//

import Foundation

struct HistoryStorage {
    
    static let shared = HistoryStorage()
    
    func saveHistory(_ history: [String: [WebViewHistory]]) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(history), forKey: "history")
        UserDefaults.standard.synchronize()
    }
    
    func removeHistory() {
        UserDefaults.standard.removeObject(forKey: "history")
        UserDefaults.standard.synchronize()
    }
    
    func getHistoryFromUserDefaults() -> [String: [WebViewHistory]]? {
        if let data = UserDefaults.standard.value(forKey: "history") as? Data {
            let decodedSports = try? PropertyListDecoder().decode([String: [WebViewHistory]].self, from: data)
            return decodedSports
        }
        return nil
    }
    
}
