//
//  FrontPageViewController.swift
//  Swift-Playground
//
//  Created by skyline on 15/9/23.
//  Copyright © 2015年 skyline. All rights reserved.
//

import Foundation
import UIKit

class UserViewController: UIViewController {
    var userId:String?
    var username:String?
    var password:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let v = UIView(frame: UIScreen.main().bounds)
        v.backgroundColor = UIColor.white()

        if let userId = self.userId {
            let userIdLabel = UILabel(frame: CGRectMake(80, 100, 200, 20))
            userIdLabel.text = "UserID: \(userId)"
            v.addSubview(userIdLabel)
        }
        
        if let username = self.username {
            let usernameLabel = UILabel(frame: CGRectMake(80, 120, 200, 20))
            usernameLabel.text = "Username: \(username)"
            v.addSubview(usernameLabel)
        }
        
        if let password = self.password {
            let passwordLabel = UILabel(frame: CGRectMake(80, 140, 200, 20))
            passwordLabel.text = "Password: \(password)"
            v.addSubview(passwordLabel)
        }
        
        self.view.addSubview(v)
    }
}