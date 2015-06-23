/*
 Copyright 2015 XWebView

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

import Foundation
import WebKit
import XWebView

class PluginBinding {
    struct Spec {
        var pluginID: String
        var argument: AnyObject! = nil
        var channelName: String! = nil
        var mainThread: Bool = false
        var lazyBinding: Bool = false
        init(pluginID: String, argument: AnyObject! = nil) {
            self.pluginID = pluginID
            self.argument = argument
        }
    }

    private var bindings = [String: Spec]()
    private let inventory: PluginInventory
    private let pluginQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)

    init(inventory: PluginInventory) {
        self.inventory = inventory
    }

    func importFromConfig(config: [String: AnyObject]) {
        for (key, val) in config {
            var spec: Spec
            if let str = val as? String where !str.isEmpty {
                // simple spec
                spec = Spec(pluginID: str)
                if last(spec.pluginID) == "?" {
                    spec.pluginID = dropLast(spec.pluginID)
                    spec.lazyBinding = true
                }
                if last(spec.pluginID) == "!" {
                    spec.pluginID = dropLast(spec.pluginID)
                    spec.mainThread = true
                }
            } else if let pluginID = val["Plugin"] as? String {
                // full spec
                spec = Spec(pluginID: pluginID, argument: val["argument"])
                spec.channelName = val["channelName"] as? String
                spec.mainThread  = val["mainThread"]  as? Bool ?? false
                spec.lazyBinding = val["lazyBinding"] as? Bool ?? false
            } else {
                println("ERROR: Unknown binding spec for namespace '\(key)'")
                continue
            }
            bindings[key] = spec
        }
    }

    func prebind(webView: WKWebView) {
        for (namespace, _) in filter(bindings, { !$0.1.lazyBinding }) {
            bind(webView, namespace: namespace)
        }
    }

    @objc func bind(namespace: AnyObject!, argument: AnyObject?, _Promise: XWVScriptObject) {
        let scriptObject = objc_getAssociatedObject(self, unsafeAddressOf(XWVScriptObject)) as? XWVScriptObject
        if let namespace = namespace as? String, let webView = scriptObject?.channel.webView {
            if let obj = bind(webView, namespace: namespace) {
                _Promise.callMethod("resolve", withArguments: [obj], resultHandler: nil)
            } else {
                _Promise.callMethod("reject", withArguments: nil, resultHandler: nil)
            }
        }
    }

    private func bind(webView: WKWebView, namespace: String) -> XWVScriptObject? {
        if let spec = bindings[namespace], let plugin: AnyClass = inventory[spec.pluginID] {
            if let object: AnyObject = instantiateClass(plugin, withArgument: spec.argument) {
                let queue = spec.mainThread ? dispatch_get_main_queue() : pluginQueue
                let channel = XWVChannel(name: spec.channelName, webView: webView, queue: queue)
                return channel.bindPlugin(object, toNamespace: namespace)
            }
            println("ERROR: Failed to create instance of plugin '\(spec.pluginID)'.")
        } else if let spec = bindings[namespace] {
            println("ERROR: Plugin '\(spec.pluginID)' not found.")
        } else {
            println("ERROR: Namespace '\(namespace)' has no binding")
        }
        return nil
    }

    private func instantiateClass(cls: AnyClass, withArgument argument: AnyObject?) -> AnyObject? {
        //XWVFactory.self  // a trick to access static method of protocol
        if class_conformsToProtocol(cls, XWVSingleton.self) {
            return cls.instance
        } else if class_conformsToProtocol(cls, XWVFactory.self) {
            if argument != nil && cls.createInstanceWithArgument != nil {
                return cls.createInstanceWithArgument!(argument)
            }
            return cls.createInstance()
        }

        var initializer = Selector("initWithArgument:")
        var args: [AnyObject]!
        if class_respondsToSelector(cls, initializer) {
            args = [ argument ?? NSNull() ]
        } else {
            initializer = Selector("init")
            if !class_respondsToSelector(cls, initializer) {
                return cls as AnyObject
            }
        }
        return XWVInvocation.construct(cls, initializer: initializer, arguments: args)
    }

}

extension PluginBinding {
    subscript (namespace: String) -> Spec? {
        get {
            return bindings[namespace]
        }
        set {
            bindings[namespace] = newValue
        }
    }
}
