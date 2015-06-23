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
    private var statusbar: StatusBar?

    override var title: String? {
        get { return "contentWebView" }
        set {}
    }

    override func loadView() {
        let rect = UIScreen.mainScreen().applicationFrame
        let webView = WKWebView(frame: rect, configuration: WKWebViewConfiguration())
        webView.UIDelegate = self
        view = webView as UIView
/*
        let info = NSBundle.mainBundle().infoDictionary!
        webview.scalesPageToFit = (info["XWSScalesPageToFit"] as? NSNumber)?.boolValue ?? false*/
        //"document.documentElement.style.webkitUserSelect='none';"
        //"document.documentElement.style.webkitTouchCallout='none';"
        // var style = document.createElement("style");
        // document.head.appendChild(style);
        // style.sheet.insertRule("* { -webkit-user-select: none; }")
        // style.sheet.insertRule("input { -webkit-user-select: auto; }")
    }

    override func viewDidLoad() {
        let webView = view as! WKWebView

        statusbar = StatusBar.instance as? StatusBar
        if let configPath = NSBundle.mainBundle().pathForResource("config", ofType: "plist"),
            let config = NSDictionary(contentsOfFile: configPath) {
            if let pref = config["StatusBar"] as? [String: AnyObject] {
                statusbar?._preferences = pref
            }
            if let pref = config["Scroll"] as? [String: AnyObject] {
                let scroll = Scroll(scrollView: webView.scrollView)
                scroll._preferences = pref
            }
            if let plugin = config["Plugin"] as? [String: AnyObject] {
                var modules = Set<String>()
                let base = NSBundle.mainBundle().bundlePath
                if let patterns = plugin["Modules"] as? [String] {
                    var gl = glob_t();
                    let flags = GLOB_APPEND | GLOB_NOESCAPE | GLOB_NOSORT
                    for pattern in patterns {
                        (base + "/" + pattern).withCString() { glob($0, flags, nil, &gl) }
                    }
                    var gen = UnsafeBufferPointer(start: gl.gl_pathv, count: gl.gl_pathc).generate()
                    while let path = gen.next() {
                        modules.insert(String.fromCString(path)!)
                    }
                    globfree(&gl)
                } else {
                    modules.insert(base)
                }

                let inventory = PluginInventory()
                var gen = modules.generate()
                while let path = gen.next() {
                    if let bundle = NSBundle(path: path) {
                        inventory.scanInBundle(bundle)
                    }
                }

                if let bindings = plugin["Bindings"] as? [String: AnyObject] {
                    let binding = PluginBinding(inventory: inventory)
                    binding.importFromConfig(bindings)
                    binding.prebind(webView)
                }
            }
        }

        if let root = NSBundle.mainBundle().resourceURL {
            var error: NSError?
            let url = root.URLByAppendingPathComponent("index.html")
            if url.checkResourceIsReachableAndReturnError(&error) {
                webView.loadFileURL(url, allowingReadAccessToURL: root)
            } else {
                webView.loadHTMLString(error!.description, baseURL: nil)
            }
        }
    }
}

extension ViewController {
    // Delegate for status bar
    override func prefersStatusBarHidden() -> Bool {
        return statusbar?._hidden ?? super.prefersStatusBarHidden()
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusbar?._style ?? super.preferredStatusBarStyle()
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return statusbar?._animation ?? super.preferredStatusBarUpdateAnimation()
    }
}

extension ViewController {
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

/*
short: plugin[!][?]
namespace:
[
    plugin: String
    argument: AnyObject  (meaningful for non-singleton)
    channelName: String
    mainThread: Bool
    lazyBinding: Bool
]*/
