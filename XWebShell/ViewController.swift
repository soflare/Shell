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

import UIKit
import WebKit
import XWebView

class ViewController: UIViewController, WKUIDelegate {
    let info = NSBundle.mainBundle().infoDictionary!
    private var statusbar: StatusBar?

    override func loadView() {
        let rect = UIScreen.mainScreen().applicationFrame
        let webview = WKWebView(frame: rect, configuration: WKWebViewConfiguration())
        webview.scrollView.bounces = (info["XWSBounceScroll"] as? NSNumber)?.boolValue ?? true
        webview.scrollView.scrollEnabled = (info["XWSScrollEnabled"] as? NSNumber)?.boolValue ?? true
        webview.scrollView.scrollsToTop = (info["XWSScrollToTop"] as? NSNumber)?.boolValue ?? true
        webview.scrollView.showsVerticalScrollIndicator = (info["XWSShowsVerticalScrollIndicator"] as? NSNumber)?.boolValue ?? true
        webview.scrollView.showsHorizontalScrollIndicator = (info["XWSShowsHorizontalScrollIndicator"] as? NSNumber)?.boolValue ?? true
        webview.scalesPageToFit = (info["XWSScalesPageToFit"] as? NSNumber)?.boolValue ?? false
        //"document.documentElement.style.webkitUserSelect='none';"
        //"document.documentElement.style.webkitTouchCallout='none';"
        // var style = document.createElement("style");
        // document.head.appendChild(style);
        // style.sheet.insertRule("* { -webkit-user-select: none; }")
        // style.sheet.insertRule("input { -webkit-user-select: auto; }")
        webview.UIDelegate = self
        view = webview as UIView
    }
    override func viewDidLoad() {
        let webview = view as! WKWebView
        webview.loadPlugin(Echo(prefix: nil), namespace: "sample.Echo")
        webview.loadPlugin(HelloWorld(), namespace: "sample.hello")
        webview.loadPlugin(Vibrate(), namespace: "sample.vibrate")
/*
        let inventory = XWVInventory()
        let manifest: [String: AnyObject]
        let plugins: [String: AnyObject]
        if let path = NSBundle.mainBundle().pathForResource("manifest", ofType: "plist") {
            manifest = NSDictionary(contentsOfFile: path) as! [String: AnyObject]
            plugins = manifest["Plugins"] as? [String: AnyObject] ?? [String: AnyObject]()
        } else {
            manifest = [String: AnyObject]()
            plugins = [String: AnyObject]()
        }
        if manifest["StatusBar"] != nil || plugins["StatusBar"] != nil {
            statusbar = StatusBar()
            if var namespace = plugins["StatusBar"] as? String {
                var bindNow: Bool = true
                if last(namespace) == "?" {
                    namespace = dropLast(namespace)
                    bindNow = false
                }
                if namespace.isEmpty {
                    namespace = "xshell.statusBar"
                }
                if bindNow {
                    webview.loadPlugin(statusbar!, namespace: namespace)
                } else {
                    inventory.registerPlugin(StatusBar.self, namespace: namespace)
                }
            }
        }*/
        webview.loadPlugin(statusbar!, namespace: "xshell.statusBar")
        webview.loadPlugin(Scroll(scrollView: webview.scrollView), namespace: "xshell.scroll")
/*
        var start_url = "index.html"
        var plugins = [String: AnyObject]() //["Extension.load"]
        if let plistPath = NSBundle.mainBundle().pathForResource("manifest", ofType: "plist") {
            if let manifest = NSDictionary(contentsOfFile: plistPath) {
                start_url = manifest["start_url"] as? String ?? start_url
                plugins = manifest["Plugins"] as? [String: AnyObject] ?? plugins
            }
        }
        let inventory = XWVInventory()
        for (name, namespace) in plugins {
            if let plugin: AnyObject = inventory.pluginClass(name) {
                let obj = XWVInvocation.construct(plugin, initializer: "init", arguments: nil)
                webview.loadPlugin(obj, namespace: namespace as? String ?? "")
            }
        }
*/
        if let root = NSBundle.mainBundle().resourceURL {
            var error: NSError?
            let url = root.URLByAppendingPathComponent("index.html")
            if url.checkResourceIsReachableAndReturnError(&error) {
                webview.loadFileURL(url, allowingReadAccessToURL: root)
            } else {
                webview.loadHTMLString(error!.description, baseURL: nil)
            }
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        //return (info["UIStatusBarHidden"] as? NSNumber)?.boolValue ?? false
        return statusbar?._hidden ?? super.prefersStatusBarHidden()
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
/*      if let s = info["UIStatusBarStyle"] as? String where s == "UIStatusBarStyleLightContent" {
            return UIStatusBarStyle.LightContent
        }
        return UIStatusBarStyle.Default*/
        return statusbar?._style ?? super.preferredStatusBarStyle()
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return statusbar?._animation ?? super.preferredStatusBarUpdateAnimation()
    }

    // UIDelegate implementation
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let dialog = ModalDialogBox(title: "", message: message, parent: self)
        dialog.alert(completionHandler)
    }
    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        let dialog = ModalDialogBox(title: "", message: message, parent: self)
        dialog.confirm(completionHandler)
    }
    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String!) -> Void) {
        let dialog = ModalDialogBox(title: "", message: prompt, parent: self)
        dialog.prompt(defaultText, handler: completionHandler)
    }
}


extension WKWebView {
    private struct key {
        static let scale = UnsafePointer<Void>(bitPattern: Selector("scalesPageToFit").hashValue)
    }
    private var sourceOfUserScript: String {
        return "(function(){\n" +
            "    var head = document.getElementsByTagName('head')[0];\n" +
            "    var nodes = head.getElementsByTagName('meta');\n" +
            "    var i, meta;\n" +
            "    for (i = 0; i < nodes.length; ++i) {\n" +
            "        meta = nodes.item(i);\n" +
            "        if (meta.getAttribute('name') == 'viewport')  break;\n" +
            "    }\n" +
            "    if (i == nodes.length) {\n" +
            "        meta = document.createElement('meta');\n" +
            "        meta.setAttribute('name', 'viewport');\n" +
            "        head.appendChild(meta);\n" +
            "    } else {\n" +
            "        meta.setAttribute('backup', meta.getAttribute('content'));\n" +
            "    }\n" +
            "    meta.setAttribute('content', 'width=device-width, user-scalable=no');\n" +
        "})();\n"
    }
    var scalesPageToFit: Bool {
        get {
            return objc_getAssociatedObject(self, key.scale) != nil
        }
        set {
            if newValue {
                if objc_getAssociatedObject(self, key.scale) != nil {
                    return
                }
                let time = WKUserScriptInjectionTime.AtDocumentEnd
                let script = WKUserScript(source: sourceOfUserScript, injectionTime: time, forMainFrameOnly: true)
                configuration.userContentController.addUserScript(script)
                objc_setAssociatedObject(self, key.scale, script, UInt(OBJC_ASSOCIATION_ASSIGN))
                if URL != nil {
                    evaluateJavaScript(sourceOfUserScript, completionHandler: nil)
                }
            } else if let script = objc_getAssociatedObject(self, key.scale) as? WKUserScript {
                objc_setAssociatedObject(self, key.scale, nil, UInt(OBJC_ASSOCIATION_ASSIGN))
                configuration.userContentController.removeUserScript(script)
                if URL != nil {
                    let source = "(function(){\n" +
                        "    var head = document.getElementsByTagName('head')[0];\n" +
                        "    var nodes = head.getElementsByTagName('meta');\n" +
                        "    for (var i = 0; i < nodes.length; ++i) {\n" +
                        "        var meta = nodes.item(i);\n" +
                        "        if (meta.getAttribute('name') == 'viewport' && meta.hasAttribute('backup')) {\n" +
                        "            meta.setAttribute('content', meta.getAttribute('backup'));\n" +
                        "            meta.removeAttribute('backup');\n" +
                        "        }\n" +
                        "    }\n" +
                    "})();"
                    evaluateJavaScript(source, completionHandler: nil)
                }
            }
        }
    }
}
