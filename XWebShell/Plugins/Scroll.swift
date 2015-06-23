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
import WebKit

class Scroll : NSObject {
    private unowned let scrollView: UIScrollView

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    convenience init?(argument: AnyObject?) {
        let rootView = UIApplication.sharedApplication().keyWindow!.rootViewController!.view
        var scrollView: UIScrollView?
        if let tag = (argument as? NSNumber)?.integerValue {
            // try to find view by tag
            let view = rootView.viewWithTag(tag)
            if let view = view as? UIScrollView {
                scrollView = view
            } else if let view = view as? WKWebView {
                scrollView = view.scrollView
            }
        } else {
            // try to find view by title of controller
            let title = argument as? String ?? ""
            var views: [AnyObject] = [ rootView ]
            do {
                let view = views.removeAtIndex(0) as! UIView
                views.extend(view.subviews)
                if title.isEmpty || (view.nextResponder() as? UIViewController)?.title == title {
                    scrollView = (view as? WKWebView)?.scrollView
                }
            } while views.count > 0 && scrollView == nil
        }
        if scrollView == nil {
            self.init(scrollView: UIScrollView(frame: CGRect.zeroRect))
            return nil
        }
        self.init(scrollView: scrollView!)
    }

    var bouncy: Bool {
        get {
            return scrollView.bounces
        }
        set {
            scrollView.bounces = newValue
        }
    }

    var enabled: Bool {
        get {
            return scrollView.scrollEnabled
        }
        set {
            scrollView.scrollEnabled = newValue
        }
    }

    var scrollsToTop: Bool {
        get {
            return scrollView.scrollsToTop
        }
        set {
            scrollView.scrollsToTop = newValue
        }
    }

    var directionalLock: Bool {
        get {
            return scrollView.directionalLockEnabled
        }
        set {
            scrollView.directionalLockEnabled = newValue
        }
    }

    var decelerationRate: NSString {
        get {
            switch scrollView.decelerationRate {
                case UIScrollViewDecelerationRateNormal:
                    return "Normal"
                case UIScrollViewDecelerationRateFast:
                    return "Fast"
                default:
                    return scrollView.decelerationRate.description
            }
        }
        set {
            if !newValue.isKindOfClass(NSString.self) {
                return
            }
            switch newValue {
                case "Normal":
                    scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
                case "Fast":
                    scrollView.decelerationRate = UIScrollViewDecelerationRateFast
                default:
                    return
            }
        }
    }

    var indicatorStyle: NSString {
        get {
            switch scrollView.indicatorStyle {
                case UIScrollViewIndicatorStyle.Default:
                    return "Default"
                case UIScrollViewIndicatorStyle.Black:
                    return "Black"
                case UIScrollViewIndicatorStyle.White:
                    return "White"
            }
        }
        set {
            if !newValue.isKindOfClass(NSString.self) {
                return
            }
            switch newValue {
                case "Default":
                    scrollView.indicatorStyle = UIScrollViewIndicatorStyle.Default
                case "Black":
                    scrollView.indicatorStyle = UIScrollViewIndicatorStyle.Black
                case "White":
                    scrollView.indicatorStyle = UIScrollViewIndicatorStyle.White
                default:
                    return
            }
        }
    }

    var showsHorizontalIndicator: Bool {
        get {
            return scrollView.showsHorizontalScrollIndicator
        }
        set {
            scrollView.showsHorizontalScrollIndicator = newValue
        }
    }
    var showsVerticalIndicator: Bool {
        get {
            return scrollView.showsVerticalScrollIndicator
        }
        set {
            scrollView.showsVerticalScrollIndicator = newValue
        }
    }

    var _preferences: [String: AnyObject] {
        get {
            return [
                "Bouncy": bouncy,
                "Enabled": enabled,
                "ScrollsToTop": scrollsToTop,
                "DirectionalLock": directionalLock,
                "DecelerationRate": decelerationRate,
                "IndicatorStyle": indicatorStyle,
                "ShowsHorizontalIndicator": showsHorizontalIndicator,
                "ShowsVerticalIndicator": showsVerticalIndicator
            ]
        }
        set {
            bouncy = (newValue["Bouncy"] as? NSNumber)?.boolValue ?? bouncy
            enabled = (newValue["Enabled"] as? NSNumber)?.boolValue ?? enabled
            scrollsToTop = (newValue["ScrollsToTop"] as? NSNumber)?.boolValue ?? scrollsToTop
            directionalLock = (newValue["DirectionalLock"] as? NSNumber)?.boolValue ?? directionalLock
            decelerationRate = newValue["DecelerationRate"] as? String ?? decelerationRate
            indicatorStyle = newValue["IndicatorStyle"] as? String ?? indicatorStyle
            showsHorizontalIndicator = (newValue["ShowsHorizontalIndicator"] as? NSNumber)?.boolValue ?? showsHorizontalIndicator
            showsVerticalIndicator = (newValue["ShowsVerticalIndicator"] as? NSNumber)?.boolValue ?? showsVerticalIndicator
        }
    }
}
