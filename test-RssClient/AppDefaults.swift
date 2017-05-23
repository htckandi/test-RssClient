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
            
            static let willParse = Notification.Name("ParseOperationWillParseNotification")
            static let didParse = Notification.Name("ParseOperationDidParseNotification")
            static let didParseAllFeeds = Notification.Name("ParseOperationDidParseAllFeedsNotification")
        }
    }
}
