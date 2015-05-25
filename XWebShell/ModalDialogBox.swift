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

class ModalDialogBox {
    let title: String
    let message: String
    unowned let parent: UIViewController
    var done = false

    init(title: String, message: String, parent: UIViewController) {
        self.title = title
        self.message = message
        self.parent = parent
    }

    func alert(handler: ()->Void) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        controller.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            (UIAlertAction)->Void in
            handler()
            self.done = true
        })
        show(controller)
    }

    func confirm(handler: (Bool)->Void) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        controller.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            (UIAlertAction)->Void in
            handler(true)
            self.done = true
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            (UIAlertAction)->Void in
            handler(false)
            self.done = true
        })
        show(controller)
    }

    func prompt(value: String!, handler: (String!)->Void) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        controller.addTextFieldWithConfigurationHandler {
            $0.text = value
        }
        controller.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            (UIAlertAction)->Void in
            let field = controller.textFields?[0] as? UITextField
            handler(field?.text)
            self.done = true
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            (UIAlertAction)->Void in
            handler(nil)
            self.done = true
        })
        show(controller)
    }

    private func show(controller: UIAlertController) {
        parent.presentViewController(controller, animated: true, completion: nil)
        while !done {
            let reason = CFRunLoopRunInMode(kCFRunLoopDefaultMode, NSDate.distantFuture().timeIntervalSinceNow, Boolean(1))
            if Int(reason) != kCFRunLoopRunHandledSource {
                break
            }
        }
    }
}
