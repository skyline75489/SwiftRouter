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
        }
    }

    var debugDescription: String {
        return description
    }
}

class RouteEntry {
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
        fatalError(RouterError.invalidRouteEntry.description)
    }

    var debugDescription: String {
        return description
    }
}

extension String {
    func stringByFilterAppSchemes() -> String {
        for scheme in appUrlSchemes {
            if hasPrefix(scheme.appending(":")) {
                return substring(from: index(startIndex, offsetBy: scheme.characters.count + 2))
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


    open func matchController(_ route: String) -> AnyObject? {
        var params = paramsInRoute(route)
        if let entry = findRouteEntry(route, params: &params) {
            let name = NSStringFromClass(entry.klass!)
            let clz = NSClassFromString(name) as! NSObject.Type
            let instance = clz.init()
            instance.setValuesForKeys(params)
            return instance
        }
        return nil
    }

    open func matchControllerFromStoryboard(_ route: String, storyboardName: String = "Storyboard") -> AnyObject? {
        var params = paramsInRoute(route)
        if let entry = findRouteEntry(route, params: &params) {
            let name = NSStringFromClass(entry.klass!)
            let clz = NSClassFromString(name) as! NSObject.Type
            let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(for: clz))
            let controllerIdentifier = name.components(separatedBy: ".").last!
            let instance = storyboard.instantiateViewController(withIdentifier: controllerIdentifier)
            instance.setValuesForKeys(params)
            return instance
        }
        return nil
    }

    open func matchHandler(_ route: String) -> (([String:String]?) -> (Bool))? {
        var a = [String:String]()
        if let entry = findRouteEntry(route, params: &a) {
            return entry.handler
        }
        return nil
    }

    fileprivate func findRouteEntry(_ route: String, params:inout [String:String]) -> RouteEntry? {
        let pathComponents = pathComponentsInRoute(route)

        var subRoutes = routeMap
        for pathComponent in pathComponents {
            for (k, v) in subRoutes {
                // match handler first
                if subRoutes[pathComponent] != nil {
                    if pathComponent == pathComponents.last {
                        let d = subRoutes[pathComponent] as! NSMutableDictionary
                        let entry = d["_entry"] as! RouteEntry
                        return entry
                    }
                    subRoutes = subRoutes[pathComponent] as! NSMutableDictionary
                    break
                }
                if (k as AnyObject).hasPrefix(":") {
                    let s = String(describing: k)
                    let key = s.substring(from: s.index(s.startIndex, offsetBy: 1))
                    params[key] = pathComponent
                    if pathComponent == pathComponents.last {
                        return (v as? NSDictionary)?[kRouteEntryKey] as? RouteEntry
                    }
                    subRoutes = subRoutes[s] as! NSMutableDictionary
                    break
                } else {
                    fatalError(RouterError.schemeNotRecognized.description)
                }
            }
        }
        return nil
    }

    fileprivate func paramsInRoute(_ route: String) -> [String: String] {

        var params = [String:String]()
        _ = findRouteEntry(route.stringByFilterAppSchemes(), params: &params)

        if let loc = route.range(of: "?") {
            let paramsString = route.substring(from: route.index(after: loc.lowerBound))
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
            path = NSString(string: route.substring(to: loc.lowerBound))
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

    open func routeURL(_ route: String) {
        if let handler = matchHandler(route) {
            let params = paramsInRoute(route)
            _ = handler(params)
        }
    }
    open func routeURL(_ route: String, navigationController: UINavigationController) {
        if let vc = matchController(route) {
            navigationController.pushViewController(vc as! UIViewController, animated: true)
        }
    }
}
