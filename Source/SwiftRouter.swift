//
//  SwiftRouter.swift
//  Swift-Playground
//
//  Created by skyline on 15/9/23.
//  Copyright © 2016年 skyline. All rights reserved.
//

import Foundation
import UIKit

var appUrlSchemes: [String] = {
    if let info: [String:AnyObject] = Bundle.main.infoDictionary as [String : AnyObject]? {
        var schemes = [String]()
        if let url = info["CFBundleURLTypes"] as? [[String:AnyObject]]?, url != nil {
            for d in url! {
                if let scheme = (d["CFBundleURLSchemes"] as? [String])?[0] {
                    schemes.append(scheme)
                }
            }
        }
        return schemes
    }
    return []
}()

enum RouterError: Error {
    case schemeNotRecognized
    case entryAlreayExisted
    case invalidRouteEntry
    case noMatchingRoute
}

extension RouterError: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        switch (self) {
        case .schemeNotRecognized:
            return "SchemeNotRecognized"
        case .entryAlreayExisted:
            return "EntryAlreayExisted"
        case .invalidRouteEntry:
            return "InvalidRouteEntry"
        case .noMatchingRoute:
            return "NoMatchingRoute"
        }
    }

    var debugDescription: String {
        return description
    }
}

private class RouteEntry {
    var pattern: String? = nil
    var handler: (([String:String]?) -> Bool)? = nil
    var klass: AnyClass? = nil

    init(pattern: String?, cls: AnyClass?=nil, handler:((_ params: [String:String]?) -> Bool)?=nil) {
        self.pattern = pattern
        self.klass = cls
        self.handler = handler
    }
}

extension RouteEntry: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        let empty = ""
        if let k = self.klass {
            return "\(self.pattern ?? empty) -> \(k)"
        }
        if let h = self.handler {
            return "\(self.pattern ?? empty) -> \(h)"
        }
        return RouterError.invalidRouteEntry.description
    }

    var debugDescription: String {
        return description
    }
}

extension String {
    func stringByFilterAppSchemes() -> String {
        for scheme in appUrlSchemes {
            if hasPrefix(scheme.appending(":")) {
                return String(self[index(startIndex, offsetBy: scheme.count + 2)...])
            }
        }
        return self
    }
}

open class Router {
    open static let shared = Router()

    fileprivate let kRouteEntryKey = "_entry"

    fileprivate var routeMap = NSMutableDictionary()

    open func map(_ route: String, controllerClass: AnyClass) {
        doMap(route, cls: controllerClass)
    }

    open func map(_ route: String, handler:@escaping ([String:String]?) -> (Bool)) {
        doMap(route, handler: handler)
    }

    fileprivate func doMap(_ route: String, cls: AnyClass?=nil, handler: (([String:String]?) -> (Bool))?=nil) -> Void {
        var r = RouteEntry(pattern: "/", cls: nil)
        if let k = cls {
            r = RouteEntry(pattern: route, cls: k)
        } else {
            r = RouteEntry(pattern: route, handler: handler)
        }
        let pathComponents = self.pathComponentsInRoute(route)
        insertRoute(pathComponents, entry: r, subRoutes: self.routeMap)
    }

    fileprivate func insertRoute(_ pathComponents: [String], entry: RouteEntry, subRoutes: NSMutableDictionary, index: Int = 0) {

        if index >= pathComponents.count {
            fatalError(RouterError.entryAlreayExisted.description)
        }
        let pathComponent = pathComponents[index]
        if subRoutes[pathComponent] == nil {
            if pathComponent == pathComponents.last {
                subRoutes[pathComponent] = NSMutableDictionary(dictionary: [kRouteEntryKey: entry])
                print("Adding Route: \(entry.description)")
                return
            }
            subRoutes[pathComponent] = NSMutableDictionary()
        }
        // recursive
        insertRoute(pathComponents, entry: entry, subRoutes: subRoutes[pathComponent] as! NSMutableDictionary, index: index+1)
    }


    open func matchController(_ route: String) throws -> AnyObject {
        var params = try paramsInRoute(route)
        let entry = try findRouteEntry(route, params: &params)
        let name = NSStringFromClass(entry.klass!)
        let clz = NSClassFromString(name) as! NSObject.Type
        let instance = clz.init()
        instance.setValuesForKeys(params)
        return instance
    }

    open func matchControllerFromStoryboard(_ route: String, storyboardName: String = "Storyboard") throws -> AnyObject {
        var params = try paramsInRoute(route)
        let entry = try findRouteEntry(route, params: &params)
        let name = NSStringFromClass(entry.klass!)
        let clz = NSClassFromString(name) as! NSObject.Type
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(for: clz))
        let controllerIdentifier = name.components(separatedBy: ".").last!
        let instance = storyboard.instantiateViewController(withIdentifier: controllerIdentifier)
        instance.setValuesForKeys(params)
        return instance
    }

    open func matchHandler(_ route: String) throws -> (([String:String]?) -> (Bool)) {
        var a = [String:String]()
        let entry = try findRouteEntry(route, params: &a)
        guard let handler = entry.handler else {
            throw RouterError.invalidRouteEntry
        }
        return handler
    }

    fileprivate func findRouteEntry(_ route: String, params:inout [String:String]) throws -> RouteEntry {
        let pathComponents = pathComponentsInRoute(route)

        var subRoutes = routeMap
        for pathComponent in pathComponents {
            for (k, v) in subRoutes {
                // match handler first
                if subRoutes[pathComponent] != nil {
                    if let d = subRoutes[pathComponent] as? NSMutableDictionary,
                        pathComponent == pathComponents.last {
                        if let entry = d[kRouteEntryKey] as? RouteEntry {
                            return entry
                        }
                    }
                    if let dict = subRoutes[pathComponent] as? NSMutableDictionary {
                        subRoutes = dict
                        break
                    }
                }
                if (k as AnyObject).hasPrefix(":") {
                    let s = String(describing: k)
                    let key = String(s[s.index(s.startIndex, offsetBy: 1)...])
                    params[key] = pathComponent
                    if pathComponent == pathComponents.last {
                        return (v as? NSDictionary)?[kRouteEntryKey] as! RouteEntry
                    }
                    subRoutes = subRoutes[s] as! NSMutableDictionary
                    break
                } else {
                    throw RouterError.schemeNotRecognized
                }
            }
        }
        throw RouterError.noMatchingRoute
    }

    fileprivate func paramsInRoute(_ route: String) throws -> [String: String] {

        var params = [String:String]()
        _ = try findRouteEntry(route.stringByFilterAppSchemes(), params: &params)

        if let loc = route.range(of: "?") {
            let paramsString = String(route[route.index(after: loc.lowerBound)...])
            let paramArray = paramsString.components(separatedBy: "&")
            for param in paramArray {
                let kv = param.components(separatedBy: "=")
                let k = kv[0]
                let v = kv[1]
                params[k] = v
            }
        }
        return params
    }

    fileprivate func pathComponentsInRoute(_ route: String) -> [String] {
        var path: NSString = NSString(string: route)
        if let loc = route.range(of: "?") {
            path = NSString(string: String(route[..<loc.lowerBound]))
        }
        var result = [String]()
        for pathComponent in path.pathComponents {
            if pathComponent == "/" {
                continue
            }
            result.append(pathComponent)
        }
        return result
    }

    open func removeAllRoutes() {
        routeMap.removeAllObjects()
    }

    open func routeURL(_ route: String) throws {
        let handler = try matchHandler(route)
        let params = try paramsInRoute(route)
        _ = handler(params)
    }

    open func routeURL(_ route: String, navigationController: UINavigationController) throws {
        if let vc = try matchController(route) as? UIViewController {
            navigationController.pushViewController(vc, animated: true)
        } else {
            throw RouterError.invalidRouteEntry
        }
    }
}
