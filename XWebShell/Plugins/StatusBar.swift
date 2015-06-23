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
import XWebView

class StatusBar : NSObject, XWVSingleton {
    private unowned let application: UIApplication
    private unowned let rootViewController: UIViewController
    private let applicationControlled: Bool

    static var instance: NSObject = { StatusBar() }()
    private override init() {
        applicationControlled = (NSBundle.mainBundle().infoDictionary?["UIViewControllerBasedStatusBarAppearance"] as? NSNumber)?.boolValue == false
        application = UIApplication.sharedApplication()
        rootViewController = application.keyWindow!.rootViewController!
        if applicationControlled {
            _hidden = application.statusBarHidden
            _style = application.statusBarStyle
            _animation = UIStatusBarAnimation.None
        } else {
            _hidden = rootViewController.prefersStatusBarHidden()
            _style = rootViewController.preferredStatusBarStyle()
            _animation = rootViewController.preferredStatusBarUpdateAnimation()
        }
    }

    var _hidden: Bool
    var hidden: Bool {
        get {
            return applicationControlled ? application.statusBarHidden : _hidden
        }
        set {
            if applicationControlled {
                application.setStatusBarHidden(newValue, withAnimation: _animation)
            } else if _hidden != newValue {
                _hidden = newValue
                let viewController = rootViewController.childViewControllerForStatusBarHidden() ?? rootViewController
                if _animation == UIStatusBarAnimation.None {
                    viewController.setNeedsStatusBarAppearanceUpdate()
                } else {
                    UIView.animateWithDuration(0.3) {
                        viewController.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            }
        }
    }

    var _style: UIStatusBarStyle
    var style: NSString {
        get {
            switch applicationControlled ? application.statusBarStyle : _style {
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
            if applicationControlled {
               application.statusBarStyle = s
            } else if _style != s {
                _style = s
                let viewController = rootViewController.childViewControllerForStatusBarStyle() ?? rootViewController
                viewController.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    var _animation: UIStatusBarAnimation
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
