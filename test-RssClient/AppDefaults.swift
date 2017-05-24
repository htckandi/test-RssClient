//
//  AppDefaults.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 21.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import Foundation

struct AppDefaults {
    
    struct Notifications {
        
        struct ParseOperation {
            
            static let willParseFeed = Notification.Name("ParseOperationWillParseFeedNotification")
            static let didParseFeed = Notification.Name("ParseOperationDidParseFeedNotification")
        }
    }
}
