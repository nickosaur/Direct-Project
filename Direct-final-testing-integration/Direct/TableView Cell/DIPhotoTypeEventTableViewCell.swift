//
//  DIPhotoTypeEventTableViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 11/12/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

class DIPhotoTypeEventTableViewCell: DIEventCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            self.timeLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    @IBOutlet weak var coverImageView: UIImageView! {
        didSet {
            self.coverImageView.contentMode = .scaleAspectFill
            self.coverImageView.setCornerRadius(radius: DIApp.Style.thumbnailCornerRaidus)
        }
    }
    @IBOutlet weak var statusDotView: DIEventStatusDotView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.selectionStyle = .none
    }
    
    
    override var event: DIEvent! {
        didSet {
            self.coverImageView.image = nil
            self.titleLabel.text = self.event?.title
            self.locationLabel.text = self.event?.location?.name
            
            if let coverURL = URL(string: self.event?.coverPath ?? "") {
                self.coverImageView.setImageWith(coverURL)
            }
            self.timeLabel.text = ((self.event.isEneded) ? "Ended " : "") +  DITime.getEndTimePrettyFormat(endTime: self.event.endTimeStamp ?? 0)
            if self.event.isLive {
                self.statusDotView.setStyle(style: .live)
            } else {
                self.statusDotView.setStyle(style: .ended)
            }
        }
    }
    
}
