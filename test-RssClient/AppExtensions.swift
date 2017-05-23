//
//  AppExtensions.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 21.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import Foundation

extension String {
    
    var trimmed: String {
        
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var internetDate: Date? {
        
        let dateFormats = [
            
            // ISO8601
            "yyyy-mm-dd'T'hh:mm",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ",
            "yyyy-MM-dd'T'HH:mmSSZZZZZ",
            
            // RFC3339
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ",
            
            // RFC822
            "EEE, d MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm zzz",
            
            // Else
            "d MMM yyyy HH:mm:ss zzz",
            "d MMM yyyy HH:mm zzz"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for dateFormat in dateFormats {
            
            dateFormatter.dateFormat = dateFormat
            
            if let date = dateFormatter.date(from: self) {
                return date
            }
        }
        
        return nil
    }
}

extension Date {
    
    static let userDateFormatter: DateFormatter = {
        
        let dateformatter = DateFormatter()
        dateformatter.doesRelativeDateFormatting = true
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        return dateformatter
    }()
    
    func userDateString () -> String? {
        
        return Date.userDateFormatter.string(from: self)
    }
}
