//
//  FrontPageViewController.swift
//  Swift-Playground
//
//  Created by skyline on 15/9/23.
//  Copyright © 2016年 skyline. All rights reserved.
//

import Foundation
import UIKit

class UserViewController: UIViewController {
    @objc var userId: String?
    @objc var username: String?
    @objc var password: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        let v = UIView(frame: UIScreen.main.bounds)
        v.backgroundColor = UIColor.white

        if let userId = self.userId {
            let userIdLabel = UILabel(frame: CGRect(x: 80, y: 100, width: 200, height: 20))
            userIdLabel.text = "UserID: \(userId)"
            v.addSubview(userIdLabel)
        }

        if let username = self.username {
            let usernameLabel = UILabel(frame: CGRect(x: 80, y: 120, width: 200, height: 20))
            usernameLabel.text = "Username: \(username)"
            v.addSubview(usernameLabel)
        }

        if let password = self.password {
            let passwordLabel = UILabel(frame: CGRect(x: 80, y: 140, width: 200, height: 20))
            passwordLabel.text = "Password: \(password)"
            v.addSubview(passwordLabel)
        }

        self.view.addSubview(v)
    }
}
