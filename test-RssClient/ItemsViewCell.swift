//
//  ItemsViewCell.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 22.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit

class ItemsViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var rssItem: RssItem! {
        didSet {
            
            if let date = rssItem.itemPubDate {
                dateLabel.text = (date as Date).userDateString()
            }
            
            titleLabel.text = rssItem.itemTitle
            descriptionLabel.text = rssItem.itemDescription
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
