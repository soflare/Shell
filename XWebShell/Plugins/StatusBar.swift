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
import UIKit

class StatusBar : NSObject {
    private unowned let viewController: UIViewController
    init(viewController: UIViewController) {
        self.viewController = viewController
        _hidden = UIApplication.sharedApplication().statusBarHidden
        _style = UIApplication.sharedApplication().statusBarStyle
    }
    override convenience init() {
        let rootViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        self.init(viewController: rootViewController)
    }

    var _hidden: Bool
    var hidden: Bool {
        get {
            return _hidden
        }
        set {
            if _hidden != newValue {
                _hidden = newValue
                viewController.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    var _style: UIStatusBarStyle
    var style: NSString {
        get {
            switch _style {
                case UIStatusBarStyle.Default:
                    return "Dark"
                case UIStatusBarStyle.LightContent:
                    return "Light"
                default:
                    return "Unknown"
            }
        }
        set {
            if !newValue.isKindOfClass(NSString.self) {
                return
            }
            let s: UIStatusBarStyle
            switch newValue {
                case "Dark": s = UIStatusBarStyle.Default
                case "Light": s = UIStatusBarStyle.LightContent
                default: s = _style
            }
            if _style != s {
                _style = s
                viewController.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    var _animation: UIStatusBarAnimation = UIStatusBarAnimation.Fade
    var animation: NSString {
        get {
            switch _animation {
                case UIStatusBarAnimation.None:
                    return "None"
                case UIStatusBarAnimation.Fade:
                    return "Fade"
                case UIStatusBarAnimation.Slide:
                    return "Slide"
            }
        }
        set {
            if !newValue.isKindOfClass(NSString.self) {
                return
            }
            switch newValue {
                case "None": _animation = UIStatusBarAnimation.None
                case "Fade": _animation = UIStatusBarAnimation.Fade
                case "Slide": _animation = UIStatusBarAnimation.Slide
                default: break
            }
        }
    }

    var _preferences: [String: AnyObject] {
        get {
            return [
                "Hidden": hidden,
                "Style": style,
                "Animation": animation
            ]
        }
        set {
            hidden = (newValue["Hidden"] as? NSNumber)?.boolValue ?? hidden
            style = newValue["Style"] as? String ?? style
            animation = newValue["Animation"] as? String ?? style
        }
    }
}
