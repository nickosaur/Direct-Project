//
//  DICategoryCollectionViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 10/30/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DICategoryCollectionViewCell.swift
 *
 * This file is used to create the view for the user’s display when choosing
 * categories for an event or for their personal selection. They are given a
 * display of all available categories, and the visual display of categories
 * which have already been selected will differ from the display of
 * categories which the user has not selected.
 */

import UIKit

// colors for different selection states
fileprivate let DICellSelectedBackgroundColorHex = "#F8BA00"
fileprivate let DICellDeSelectedBackgroundColorHex = "#D6D5D5"
fileprivate let DICategoryLabelDefaultTextColor = "#5E5E5E"
fileprivate let DICategoryLabelHighlightColor = "#FFFFFF"

class DICategoryCollectionViewCell: UICollectionViewCell {
    // the title of the category as a string
    var categoryText: String? {
        didSet {
            self.categoryLabel.text = categoryText
        }
    }
    
    // the title of the category for the UI
    @IBOutlet weak var categoryLabel: UILabel!
    
    // whether the category is selected
    var isPreselected = false
    
    /* layoutSubviews
     *
     * This function sets the positioning of the subviews
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
    }
    
    /* awakeFromNib
     *
     * This function guarantees that the view will have all outlet instance variables
     * set for the display.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.clipsToBounds = true
        self.setDeseletedUI()
    }
    
    /* isSelected
     *
     * This function will call a helper method to set the display of the category
     * based on whether the user has selected that option or not.
     */
    override var isSelected: Bool {
        didSet {
            if self.isSelected || self.isPreselected {
                self.setSelectionUI()
            } else {
                self.setDeseletedUI()
            }
        }
    }
    
    /* setSelectionUI
     *
     * This function defines the display for a category option which the user has
     * selected.
     */
    func setSelectionUI() {
        self.categoryLabel.textColor = UIColor(hexString: DICategoryLabelHighlightColor)
        self.backgroundColor = UIColor(hexString: DICellSelectedBackgroundColorHex)
        triggerFeedbackImpact()
    }
    
    /* setDeselectedUI
     *
     * This function defines the display for a category option which the user has
     * not selected.
     */
    func setDeseletedUI() {
        self.categoryLabel.textColor = UIColor(hexString: DICategoryLabelDefaultTextColor)
        self.backgroundColor = UIColor(hexString: DICellDeSelectedBackgroundColorHex)
    }

}
