//
//  FeedsViewCell.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 13.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit

class FeedsViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    var rssFeed: RssFeed! {
        didSet {
            
            titleLabel.text = rssFeed.feedTitle
            descriptionLabel.text = rssFeed.feedDescription
            
            let newItemsCount = rssFeed.feedItems?.count ?? 0
            countLabel.text = newItemsCount == 0 ? " " : String(newItemsCount)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
