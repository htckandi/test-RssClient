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
        
        // Добавляем KVO обозреватель изменения количества операций в параллельном потоке
        parseQueue.addObserver(self, forKeyPath: "operations", options: .new, context: nil)
                
        // Ограничиваем количество одновременно выполныемых операций с целью экономии аппаратных ресурсов
        parseQueue.maxConcurrentOperationCount = 3
    }
    
    deinit {
        
        // Удаляем KVO обозреватель
        parseQueue.removeObserver(self, forKeyPath: "operations", context: nil)
    }
    
    /// Обрабатывает KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // Проверяем количество операций в параллельном потоке
        if object as? OperationQueue == parseQueue && keyPath == "operations" && parseQueue.operations.count == 0 {
            
            // Публикуем уведомление о завершении выполнения всех операций
            NotificationCenter.default.post(name: AppDefaults.Notifications.ParseOperation.didParseAllFeeds, object: nil)
        }
    }
    
    /// Обновление всех существующих каналов
    func updateFeeds () {
        
        // Готовим запрос к контексту
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RssFeed.fetchRequest()
        
        // Запрашиваем контекст
        if let result = try? managedObjectContext.fetch(fetchRequest), let objects = result as? [RssFeed] {
            
            // Получаем ссылки на существующие каналы
            let feedsLinks = objects.flatMap{ $0.feedLink }
            
            // Обрабатываем каждый существующий канал
            for feedLink in feedsLinks {
                parseFeed(URL(string: feedLink)!)
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
