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

    func testDuplicateSubpaths() {
        let router = Router()
        router.map("/users/:userId", controllerClass: UserViewController.self)

        func testRoute(_ route: String, isKindOf clazz: AnyClass) {
            if let controller = try? router.matchController(route) {
                XCTAssertTrue(controller.isKind(of: clazz))
            } else {
                XCTFail("Route \(route) is not a mapped route")
            }
        }

        func testRouteFails(_ route: String) {
            if let _ = try? router.matchController(route) {
                XCTFail("Route \(route) is not a mapped route")
            }
        }

        testRoute("/users/foo", isKindOf: UserViewController.self)
        // we can't add a path to /users
        testRouteFails("/users")

        router.map("/users/bar", controllerClass: AboutViewController.self)
        testRoute("/users/foo", isKindOf: UserViewController.self)
        testRoute("/users/bar", isKindOf: AboutViewController.self)
        testRouteFails("/users")
    }

    func testRouteController() {
        let router = Router.shared

        router.map("/about", controllerClass: AboutViewController.self)
        router.map("/user/:userId", controllerClass: UserViewController.self)
        router.map("/story/:storyId", controllerClass: StoryViewController.self)
        router.map("/user/:userId/story", controllerClass: StoryListViewController.self)

        router.map("/anotherScreenFromStoryboard/:identifier", controllerClass: StoryboardViewController.self)

        func testRoute(_ route: String, isKindOf clazz: AnyClass) {
            if let controller = try? router.matchController(route) {
                XCTAssertTrue(controller.isKind(of: clazz))
            } else {
                XCTFail("Route \(route) is not a mapped route")
            }
        }

        testRoute("/about", isKindOf: AboutViewController.self)
        testRoute("/about", isKindOf: AboutViewController.self)
        testRoute("/user/1", isKindOf: UserViewController.self)
        testRoute("/story/2", isKindOf: StoryViewController.self)
        testRoute("/user/2/story", isKindOf: StoryListViewController.self)
        testRoute("/anotherScreenFromStoryboard/1010", isKindOf: StoryboardViewController.self)

        testRoute("/user/1?username=hello&password=123", isKindOf: UserViewController.self)
        if let obj = try? router.matchController("/user/1?username=hello&password=123"),
            let vc = obj as? UserViewController {
            XCTAssertEqual(vc.userId, "1")
            XCTAssertEqual(vc.username, "hello")
            XCTAssertEqual(vc.password, "123")
        } else {
            XCTFail("Not a valid route")
        }

        if let obj = try? router.matchControllerFromStoryboard("/anotherScreenFromStoryboard/1010", storyboardName: "MyStoryboard"),
            let storyboardController = obj as? StoryboardViewController {
            XCTAssertEqual(storyboardController.identifier, "1010")
            // Test user defined runtime attribute value (set in storyboard)
            XCTAssertEqual(storyboardController.valueDefinedInStoryboard, "Just testing")
        } else {
            XCTFail("Not a valid route")
        }

        if let obj = try? router.matchControllerFromStoryboard("/anotherScreenFromStoryboard/1010"),
            let storyboardController2 =  obj as? StoryboardViewController {
            XCTAssertEqual(storyboardController2.valueDefinedInStoryboard, "Default storyboard text")
        } else {
            XCTFail("Not a valid route")
        }
    }

    func testRouteHandler() {
        let router = Router.shared
        router.map("/user/add", handler: { (params: [String: String]?) -> (Bool) in
            XCTAssertNotNil(params)
            if let params = params {
                XCTAssertEqual(params["username"], "hello")
                XCTAssertEqual(params["password"], "123")
            }
            return true
        })

        let handler = try? router.matchHandler("/user/add")
        XCTAssertNotNil(handler)

        do {
            try router.routeURL("/user/add?username=hello&password=123")
        } catch {
            XCTFail("Route failed")
        }
    }

    func testRemoveAllHandlers() {
        let router = Router.shared
        router.map("/user/:userId", controllerClass: UserViewController.self)
        XCTAssertNotNil(try? router.matchController("/user/1"))

        router.removeAllRoutes()
        XCTAssertNil(try? router.matchController("/user/1"))
    }
}
