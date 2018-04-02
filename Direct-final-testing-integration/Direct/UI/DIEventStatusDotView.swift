//
//  DIEventStatusDotView.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventStatusDotView.swift
 *
 * This file is used to define the view of the label written under an event which
 * gives the user information about the time of the event relative to the current
 * event. For example, it might tell you the event was 1 day ago, or happening
 * now. It will display this relative time string with a colorful dot which expresses
 * the state of the event (ended, happening now, or upcoming).
 */

import UIKit

// two possible versions of dots
enum DIEventStatusDotViewStyle {
    case live
    case ended
}

class DIEventStatusDotView: UIView {
    /* awakeFromNib
     *
     * This function guarantees that the view will have all outlet instance variables
     * set for the display.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor(hexString: "#1DB100")
        self.layer.cornerRadius = self.frame.size.width / 2
    }
    
    /* setStyle
     *
     * This function is used to set the color of the dot based on the event status. It
     * will show a gray dot for an event which has ended and a green dot otherwise.
     */
    func setStyle(style: DIEventStatusDotViewStyle) {
        if style == .ended {
            self.backgroundColor = DIApp.Style.Color.endedGray
        } else {
            self.backgroundColor = UIColor(hexString: "#1DB100")
        }
    }
}
