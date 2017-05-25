//
//  AppAssist.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 21.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit
import CoreData

/// Ассистент приложения
class AppAssist: NSObject {
    
    /// Отображение лога
    class func log(_ sender: Any, function: String, message: String) {
        print("\(Date()): " + "\(sender)" + ": " + function + ": " + message)
    }
    
    /// Синглтон ассистента приложения
    static let shared = AppAssist()
    
    /// Главный контекст
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    /// Параллельный поток для операций обработки каналов
    let parseQueue = OperationQueue()
    
    override init() {
        super.init()
                
        // Ограничиваем количество одновременно выполныемых операций с целью экономии аппаратных ресурсов
        parseQueue.maxConcurrentOperationCount = 3
    }
    
    /// Обновление всех существующих каналов
    func updateFeeds () {
        
        // Готовим запрос к контексту
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RssFeed.fetchRequest()
        
        // Запрашиваем контекст
        if let result = try? managedObjectContext.fetch(fetchRequest), let objects = result as? [RssFeed] {
            
            // Получаем ссылки на существующие каналы
            let feedsUris = objects.flatMap{ $0.feedUri }
            
            // Обрабатываем каждый существующий канал
            for feedUri in feedsUris {
                parseFeed(URL(string: feedUri)!)
            }
        }
    }
    
    /// Обработка канала
    func parseFeed(_ defaultURL: URL) {
        
        // Проверяем наличие в паралельном потоке операции обработки канала с указанной ссылкой
        if !parseQueue.operations.contains(where: { $0.name == defaultURL.absoluteString }) {
            
            // Добавляем в параллельный поток новую операцию обработки канала
            parseQueue.addOperation(FeedParseOperation(defaultURL))
        }
    }
}
