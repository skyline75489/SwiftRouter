//
//  SwiftRouter.swift
//  Swift-Playground
//
//  Created by skyline on 15/9/23.
//  Copyright © 2015年 skyline. All rights reserved.
//

import Foundation
import UIKit

var appUrlSchemes:[String] = {
    if let info:[String:AnyObject] = NSBundle.mainBundle().infoDictionary {
        var schemes = [String]()
        if let url = info["CFBundleURLTypes"] as? [[String:AnyObject]]? where url != nil {
            for d in url! {
                if let scheme = (d["CFBundleURLSchemes"] as? [String])?[0]{
                    schemes.append(scheme)
                }
            }
        }
        return schemes
    }
    return []
}()

enum RouterError:ErrorType {
    case SchemeNotRecognized
    case EntryAlreayExisted
    case InvalidRouteEntry
    func message() -> String {
        switch (self) {
        case .SchemeNotRecognized:
            return "SchemeNotRecognized"
        case .EntryAlreayExisted:
            return "EntryAlreayExisted"
        case .InvalidRouteEntry:
            return "InvalidRouteEntry"
        }
    }
}

class RouteEntry {
    var pattern: String? = nil
    var handler: (([String:String]?) -> Bool)? = nil
    var klass: AnyClass? = nil
    
    init(pattern:String?, cls: AnyClass?=nil, handler:((params: [String:String]?) -> Bool)?=nil) {
        self.pattern = pattern
        self.klass = cls
        self.handler = handler
    }
}

extension RouteEntry: CustomStringConvertible, CustomDebugStringConvertible {
    internal var description: String {
        let empty = ""
        if let k = self.klass {
            return "\(self.pattern ?? empty) -> \(k)"
        }
        if let h = self.handler {
            return "\(self.pattern ?? empty) -> \(h)"
        }
        fatalError(RouterError.InvalidRouteEntry.message())
    }
    
    internal var debugDescription: String {
        return description
    }
}

extension String {
    func stringByFilterAppSchemes() -> String {
        for scheme in appUrlSchemes {
            if self.hasPrefix(scheme.stringByAppendingString(":")) {
                return self.substringFromIndex(self.startIndex.advancedBy((scheme.characters.count + 2)))
            }
        }
        return self
    }
}

public class Router {
    public static let sharedInstance = Router()
    
    private let kRouteEntryKey = "_entry"
    
    private var routeMap = NSMutableDictionary()

    public func map(route: String, controllerClass: AnyClass) {
        self.doMap(route, cls: controllerClass)
    }
    
    public func map(route: String, handler:([String:String]?) -> (Bool)) {
        self.doMap(route, handler: handler)
    }
    
    private func doMap(route: String, cls: AnyClass?=nil, handler:(([String:String]?) -> (Bool))?=nil) -> Void {
        var r = RouteEntry(pattern: "/", cls: nil)
        if let k = cls {
            r = RouteEntry(pattern: route, cls: k)
        } else {
            r = RouteEntry(pattern: route, handler: handler)
        }
        let pathComponents = self.pathComponentsInRoute(route)
        self.insertRoute(pathComponents, entry: r, subRoutes: self.routeMap)
    }
    
    private func insertRoute(pathComponents: [String], entry: RouteEntry, subRoutes: NSMutableDictionary, index: Int = 0){

        if index >= pathComponents.count {
            fatalError(RouterError.EntryAlreayExisted.message())
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
        self.insertRoute(pathComponents, entry: entry, subRoutes: subRoutes[pathComponent] as! NSMutableDictionary, index: index+1)
    }
    
    
    public func matchController(route: String) -> AnyObject? {
        var params = self.paramsInRoute(route)
        if let entry = self.findRouteEntry(route, params: &params) {
            let name = NSStringFromClass(entry.klass!)
            let clz = NSClassFromString(name) as! NSObject.Type
            let instance = clz.init()
            instance.setValuesForKeysWithDictionary(params)
            return instance
        }
        return nil;
    }
    
    public func matchControllerFromStoryboard(route: String, storyboardName: String = "Storyboard") -> AnyObject? {
        var params = self.paramsInRoute(route)
        if let entry = self.findRouteEntry(route, params: &params) {
            let name = NSStringFromClass(entry.klass!)
            let clz = NSClassFromString(name) as! NSObject.Type
            let storyboard = UIStoryboard(name: storyboardName, bundle: NSBundle(forClass: clz))
            let controllerIdentifier = name.componentsSeparatedByString(".").last!
            let instance = storyboard.instantiateViewControllerWithIdentifier(controllerIdentifier)
            instance.setValuesForKeysWithDictionary(params)
            return instance
        }
        return nil;
    }
    
    public func matchHandler(route: String) -> (([String:String]?) -> (Bool))? {
        var a = [String:String]()
        if let entry = self.findRouteEntry(route, params: &a) {
            return entry.handler
        }
        return nil
    }

    private func findRouteEntry(route: String, inout params:[String:String]) -> RouteEntry? {
        let pathComponents = self.pathComponentsInRoute(route)
        
        var subRoutes = self.routeMap
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
                if k.hasPrefix(":") {
                    let s = String(k)
                    let key = s.substringFromIndex(s.startIndex.advancedBy(1))
                    params[key] = pathComponent
                    if pathComponent == pathComponents.last {
                        return v[kRouteEntryKey] as? RouteEntry
                    }
                    subRoutes = subRoutes[s] as! NSMutableDictionary
                    break
                } else {
                    fatalError(RouterError.SchemeNotRecognized.message())
                }
            }
        }
        return nil
    }
    
    private func paramsInRoute(route: String) -> [String: String] {

        var params = [String:String]()
        self.findRouteEntry(route.stringByFilterAppSchemes(), params: &params)
        
        if let loc = route.rangeOfString("?") {
            let paramsString = route.substringFromIndex(loc.startIndex.advancedBy(1))
            let paramArray = paramsString.componentsSeparatedByString("&")
            for param in paramArray {
                let kv = param.componentsSeparatedByString("=")
                let k = kv[0]
                let v = kv[1]
                params[k] = v
            }
        }
        return params
    }
    
    private func pathComponentsInRoute(route: String) -> [String] {
        var path:NSString = NSString(string: route)
        if let loc = route.rangeOfString("?") {
            path = NSString(string: route.substringToIndex(loc.startIndex))
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
    
    public func removeAllRoutes() {
        self.routeMap.removeAllObjects()
    }
    
    public func routeURL(route:String) {
        if let handler = self.matchHandler(route) {
            let params = self.paramsInRoute(route)
            handler(params)
        }
    }
    public func routeURL(route:String, navigationController: UINavigationController) {
        if let vc = self.matchController(route) {
            navigationController.pushViewController(vc as! UIViewController, animated: true)
        }
    }
}
