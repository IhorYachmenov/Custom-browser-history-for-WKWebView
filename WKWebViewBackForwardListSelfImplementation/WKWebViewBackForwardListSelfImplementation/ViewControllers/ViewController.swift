//
//  ViewController.swift
//  WKWebViewBackForwardListSelfImplementation
//
//  Created by iOS on 08.03.2021.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    
    
    lazy var button: UIButton = {
        let view = UIButton(frame: CGRect(x: UIScreen.main.bounds.maxX / 2 - (UIScreen.main.bounds.width / 4), y: UIScreen.main.bounds.maxY / 2 - 25, width: UIScreen.main.bounds.width / 2, height: 50))
        view.backgroundColor = .systemPink
        view.setTitle("SHOW", for: .normal)
        view.addTarget(self, action: #selector(openWWW(_:)), for: .touchUpInside)
        return view
        
    }()
    
    @objc func openWWW(_ sender: UIButton) {
        
        let controller = WebView()
        controller.keyHistory = key
        controller.initialUrl = initUrl
        show(controller, sender: sender)
        
    }
    let key = "hdrezkaaa"
    let initUrl = "https://rezka.ag"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(button)
        
        guard (HistoryStorage.shared.getHistoryFromUserDefaults()?[key] != nil) else {
            return
        }
        let url = HistoryStorage.shared.getHistoryFromUserDefaults()![key]
        for i in url! {
            print(i.url)
        }
        
        
    }


}

