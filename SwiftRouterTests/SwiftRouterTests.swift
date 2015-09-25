//
//  SwiftRouterTests.swift
//  SwiftRouterTests
//
//  Created by skyline on 15/9/24.
//  Copyright © 2015年 skyline. All rights reserved.
//

import XCTest
@testable import SwiftRouter

class SwiftRouterTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRouteController() {
        let router = Router.sharedInstance
        router.map("/user/:userId", controllerClass: UserViewController.self)
        router.map("/story/:storyId", controllerClass: StoryViewController.self)
        router.map("/user/:userId/story", controllerClass: StoryListViewController.self)
        
        XCTAssertTrue(router.matchController("/user/1")!.isKindOfClass( UserViewController.self))
        XCTAssertTrue(router.matchController("/story/2")!.isKindOfClass( StoryViewController.self))
        XCTAssertTrue(router.matchController("/user/2/story")!.isKindOfClass( StoryListViewController.self))
        
        let vc = router.matchController("/user/1?username=hello&password=123") as! UserViewController
        XCTAssertEqual(vc.userId, "1")
        XCTAssertEqual(vc.username, "hello")
        XCTAssertEqual(vc.password, "123")
    }
    
    func testRouteHandler() {
        let router = Router.sharedInstance
        router.map("/user/add", handler: { (params:[String: String]?) -> (Bool) in
            XCTAssertNotNil(params)
            if let params = params {
                XCTAssertEqual(params["username"], "hello")
                XCTAssertEqual(params["password"], "123")
            }
            return true
        })
        
        let handler = router.matchHandler("/user/add")
        XCTAssertNotNil(handler)
        
        router.routeURL("/user/add?username=hello&password=123")
    }
}
