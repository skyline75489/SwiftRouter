//
//  ViewController.swift
//  SwiftRouterExample
//
//  Created by skyline on 15/9/24.
//  Copyright © 2015年 skyline. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.routeButton.addTarget(self, action: #selector(doRoute), for: UIControlEvents.touchDown)
        self.clearButton.addTarget(self, action: #selector(doClear), for: UIControlEvents.touchDown)
        // Do any additional setup after loading the view, typically from a nib.
    }

    func doRoute() {
        if let url = self.textField.text {
            try? Router.shared.routeURL(url, navigationController: self.navigationController!)
        }
    }

    func doClear() {
        self.textField.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
