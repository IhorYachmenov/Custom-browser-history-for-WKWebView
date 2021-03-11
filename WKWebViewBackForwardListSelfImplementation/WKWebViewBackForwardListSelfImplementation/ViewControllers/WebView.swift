//
//  WebView.swift
//  WKWebViewBackForwardListSelfImplementation
//
//  Created by iOS on 08.03.2021.
//

import Foundation
import UIKit
import WebKit

struct WebViewHistory: Codable, Hashable {
    
    let url: String
    
    init(_ url: String) {
        self.url = url
    }
    
    static func == (lhs: WebViewHistory, rhs: WebViewHistory) -> Bool {
        return lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

class WebView: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var initialUrl: String!
    var keyHistory: String!
    
    var checkButton: UIButton!
    
    lazy var webView: WKWebView = {
        let view = WKWebView(frame: CGRect(x: 0, y: 50, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.navigationDelegate = self
        view.uiDelegate = self
        return view
    }()
    
    lazy var bottomMenu: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 100, width: UIScreen.main.bounds.width, height: 50))
        view.backgroundColor = .systemGreen
 
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 25
        
        stack.layer.borderWidth = 1
        stack.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.backgroundColor = .red
        view.addSubview(stack)
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width / 3, height: 50))
        backButton.setTitle("<-", for: .normal)
        backButton.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
        
        let forwardButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width / 3, height: 50))
        forwardButton.setTitle("->", for: .normal)
        forwardButton.addTarget(self, action: #selector(forward(_:)), for: .touchUpInside)
        
        let updateButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width / 3, height: 50))
        updateButton.setTitle("UPDATE", for: .normal)
        updateButton.addTarget(self, action: #selector(update(_:)), for: .touchUpInside)
        
        checkButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width / 3, height: 50))
        checkButton.setTitle("CHECK", for: .normal)
        checkButton.addTarget(self, action: #selector(check(_:)), for: .touchUpInside)
        
        stack.distribution = .fillEqually
        
        stack.addArrangedSubview(backButton)
        stack.addArrangedSubview(forwardButton)
        stack.addArrangedSubview(updateButton)
        stack.addArrangedSubview(checkButton)
        
        return view
    }()
        
    @objc func back(_ sender: UIButton) {
        print("back")
        
        PlayerHistory.shared.backPressed = true
        PlayerHistory.shared.forwardPressed = false
    
        let url = PlayerHistory.shared.moveThroughHistory(key: keyHistory, direction: false)
        
        guard url != nil else {
            return
        }
        
        webView.load(URLRequest(url: URL(string: url!)!))

    }
    
    @objc func forward(_ sender: UIButton) {
        print("forward")
        
        PlayerHistory.shared.forwardPressed = true
        PlayerHistory.shared.backPressed = false
        
        let url = PlayerHistory.shared.moveThroughHistory(key: keyHistory, direction: true)

        guard url != nil else {
            return
        }

        webView.load(URLRequest(url: URL(string: url!)!))

        
    }
    
    @objc func update(_ sender: UIButton) {
        print("update")
        webView.reload()
    }
    
    @objc func check(_ sender: UIButton) {
        print("check current user history")
        print("------------")
        guard (HistoryStorage.shared.getHistoryFromUserDefaults()?[keyHistory] != nil) else {
            return
        }
        let url = HistoryStorage.shared.getHistoryFromUserDefaults()![keyHistory]
        for i in url! {
            print(i.url)
        }
        
    }
    
    override func viewDidLoad() {
        self.view.addSubview(webView)
        self.view.addSubview(bottomMenu)
        
        let request = URLRequest(url: URL(string: PlayerHistory.shared.getUrlForFirstLoading(initURL: initialUrl, key: keyHistory))!)
        webView.load(request)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        self.check(self.checkButton)
        PlayerHistory.shared.webViewWillBeClosedSaveHistory(key: keyHistory)
        print("I AM GO TO HOME")
    }
    
    var counterHowManyTimesUserGetResponce = 0
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if (navigationResponse.isForMainFrame == true) {
            counterHowManyTimesUserGetResponce += 1
            let url = navigationResponse.response.url!.absoluteURL.description
            if (PlayerHistory.shared.backPressed == true || PlayerHistory.shared.forwardPressed == true)
            {
                PlayerHistory.shared.backPressed = false
                PlayerHistory.shared.forwardPressed = false
                print("Response: doesn't need update")
                PlayerHistory.shared.setCurrentPosition(url: url, key: self.keyHistory)
                
            } else {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    
                    print("Response: \(url)")
                    
                    guard self.counterHowManyTimesUserGetResponce > 1 else { return }
                                        
                    DispatchQueue.main.async {
                        PlayerHistory.shared.removeUnusedPeaceOfHistory(key: self.keyHistory)
                        PlayerHistory.shared.updatePlayerHistory(backlisk: [url], key: self.keyHistory)
                    }
                }
            }
        }
        decisionHandler(.allow)
    }
    
}

struct PlayerHistory {
    
    static var shared = PlayerHistory()
    
    var historyExist: Bool = false
    var historyCurrentPosition: Int = 0
    var historyLastPositionBeforeUpdatingHistory: Int!
    var userHistoryKey: String!
    
    var backPressed: Bool!
    var forwardPressed: Bool!
    
    var urlOfPlayer: String!
    
    // Function only for first loading inside <viewDidLoad or another method from app LifeCycle>.
    mutating func getUrlForFirstLoading(initURL: String, key: String) -> String {
        
        urlOfPlayer = initURL
        
        guard HistoryStorage.shared.getHistoryFromUserDefaults() != nil else {
            updateFirstElement(key: key, url: initURL)
            return initURL
        }
        
        guard HistoryStorage.shared.getHistoryFromUserDefaults()![key] != nil else {
            return initURL
        }
        
        let position = HistoryStorage.shared.getHistoryFromUserDefaults()![key]!.count - 1
        
        historyExist = true
        historyCurrentPosition = position
        userHistoryKey = key
        let initUrlFromHistoryStorage = HistoryStorage.shared.getHistoryFromUserDefaults()![key]!.last!.url
        
        return initUrlFromHistoryStorage
    }
    
    // Create new or update exist history, use this method indsede <decidePolicyForNavigation>.
    mutating func updatePlayerHistory(backlisk: [String], key: String) {
        
        var history = [WebViewHistory]()
        
        for i in backlisk {
            history.append(WebViewHistory(i))
        }
        
        if (historyExist == true) {
            // If old history exist need compound both and then to save.
            
            let oldHistory = HistoryStorage.shared.getHistoryFromUserDefaults()![key]

            let oldAndNewHostoryTogether = oldHistory! + history
            
            var keyValuePair = Dictionary<String, [WebViewHistory]>()
            keyValuePair.updateValue(oldAndNewHostoryTogether, forKey: key)
            
            HistoryStorage.shared.removeHistory()
            HistoryStorage.shared.saveHistory(keyValuePair)
            
            setCurrentPosition(url: backlisk.last!, key: key)
        } else {
            var keyValuePair = Dictionary<String, [WebViewHistory]>()
            keyValuePair.updateValue(history, forKey: key)
            
            historyExist = true
            
            HistoryStorage.shared.removeHistory()
            HistoryStorage.shared.saveHistory(keyValuePair)
            setCurrentPosition(url: backlisk.last!, key: key)
        }
    }
        
    
    // Before using this method check if result don't equals nil. Use this method for navigation beetween history
    func moveThroughHistory(key: String, direction: Bool) -> String? {
        
        guard  historyExist != false else {
            return nil
        }
        
        let history = HistoryStorage.shared.getHistoryFromUserDefaults()![key]!
        
        if (direction == true) {
            let index = historyCurrentPosition + 1
            guard index != history.count else { return nil }
            return history[index].url
        } else {
            let index = historyCurrentPosition - 1
            guard index > 0 else { return history[0].url }
            return history[index].url
        }
        
        
    }
    
    // Method <setCurrentPosition> each time set position at history
    mutating func setCurrentPosition(url: String, key: String) {
        
        guard HistoryStorage.shared.getHistoryFromUserDefaults() != nil else { return }
        guard HistoryStorage.shared.getHistoryFromUserDefaults()![key] != nil else { return }
        
        let history = HistoryStorage.shared.getHistoryFromUserDefaults()![key]
        let index = history?.firstIndex(of: WebViewHistory(url))
        
        guard index != nil else {
            historyCurrentPosition = 0
            return
        }
        historyCurrentPosition = index!
    }
    
    // <removeUnusedPeaceOfHistory> need use when user want open new page staying inside the middle of history
    mutating func removeUnusedPeaceOfHistory(key: String) {
        
        guard HistoryStorage.shared.getHistoryFromUserDefaults() != nil else {
            return
        }
        
        guard HistoryStorage.shared.getHistoryFromUserDefaults()![key] != nil else {
            return
        }
        
        var history = HistoryStorage.shared.getHistoryFromUserDefaults()![key]!
        let startIndex = historyCurrentPosition + 1
        let endIndex = history.endIndex - 1
        let countOfAllElements = history.count
        
        guard startIndex != countOfAllElements else { return }
        let range = startIndex...endIndex
        history.removeSubrange(range)
        
        var keyValuePair = Dictionary<String, [WebViewHistory]>()
        keyValuePair.updateValue(history, forKey: key)
        
        HistoryStorage.shared.removeHistory()
        HistoryStorage.shared.saveHistory(keyValuePair)
    }
        
    // Use <updateFirstElement> inside <getUrlForFirstLoading> if history doesn't exist
    private mutating func updateFirstElement(key: String, url: String) {
        var history = [WebViewHistory]()
        history.insert(WebViewHistory(url), at: 0)
        
        var keyValuePair = Dictionary<String, [WebViewHistory]>()
        keyValuePair.updateValue(history, forKey: key)
        
        HistoryStorage.shared.saveHistory(keyValuePair)
        historyExist = true
        historyCurrentPosition = 0
        
    }
    
    // Use <webViewWillBeClosedSaveHistory> when WKWebView should be closed, if the user moves through history new position will be saved.
    mutating func webViewWillBeClosedSaveHistory(key: String) {
        let history = HistoryStorage.shared.getHistoryFromUserDefaults()![key]!
        let currentPosition = historyCurrentPosition + 1
        guard currentPosition != history.count else { return }
        removeUnusedPeaceOfHistory(key: key)
    }
}
