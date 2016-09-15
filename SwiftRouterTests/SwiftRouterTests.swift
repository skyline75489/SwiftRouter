//
//  SwiftRouterTests.swift
//  SwiftRouterTests
//
//  Created by skyline on 15/9/24.
//  Copyright © 2016年 skyline. All rights reserved.
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
        let router = Router.shared

        router.map("/about", controllerClass: AboutViewController.self)
        router.map("/user/:userId", controllerClass: UserViewController.self)
        router.map("/story/:storyId", controllerClass: StoryViewController.self)
        router.map("/user/:userId/story", controllerClass: StoryListViewController.self)

        router.map("/anotherScreenFromStoryboard/:identifier", controllerClass: StoryboardViewController.self)
        
        XCTAssertTrue(router.matchController("/about")!.isKind(of: AboutViewController.self))
        XCTAssertTrue(router.matchController("/user/1")!.isKind(of: UserViewController.self))
        XCTAssertTrue(router.matchController("/story/2")!.isKind(of: StoryViewController.self))
        XCTAssertTrue(router.matchController("/user/2/story")!.isKind(of: StoryListViewController.self))
        XCTAssertTrue(router.matchController("/anotherScreenFromStoryboard/1010")!.isKind(of: StoryboardViewController.self))
        
        let vc = router.matchController("/user/1?username=hello&password=123") as! UserViewController
        XCTAssertEqual(vc.userId, "1")
        XCTAssertEqual(vc.username, "hello")
        XCTAssertEqual(vc.password, "123")
        
        let storyboardController = router.matchControllerFromStoryboard("/anotherScreenFromStoryboard/1010", storyboardName: "MyStoryboard") as! StoryboardViewController
        XCTAssertEqual(storyboardController.identifier, "1010")
        // Test user defined runtime attribute value (set in storyboard)
        XCTAssertEqual(storyboardController.valueDefinedInStoryboard, "Just testing")
        
        let storyboardController2 = router.matchControllerFromStoryboard("/anotherScreenFromStoryboard/1010") as! StoryboardViewController
        XCTAssertEqual(storyboardController2.valueDefinedInStoryboard, "Default storyboard text")
    }
    
    func testRouteHandler() {
        let router = Router.shared
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
    
    func testRemoveAllHandlers() {
        let router = Router.shared
        router.map("/user/:userId", controllerClass: UserViewController.self)
        XCTAssertTrue(router.matchController("/user/1")!.isKind(of: UserViewController.self))

        router.removeAllRoutes()
        XCTAssertNil(router.matchController("/user/1"))
    }
}
