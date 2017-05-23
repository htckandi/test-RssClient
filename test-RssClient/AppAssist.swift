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
    
    /// Функция лога
    class func log(_ sender: Any, function: String, message: String) {
        print("\(Date()): " + "\(sender)" + ": " + function + ": " + message)
    }
    
    /// Синглтон ассистента приложения
    static let shared = AppAssist()
    
    /// Делегат приложения
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    /// Параллельный поток для операций загрузки канала
    let parseQueue = OperationQueue()
    
    override init() {
        super.init()
        
        // Добавляем KVO обозреватель изменения количества операций в параллельном потоке
        parseQueue.addObserver(self, forKeyPath: "operations.count", options: .new, context: nil)
                
        // Для экономии аппаратных ресурсов выполняем в параллельным потоке одновременно только одну операцию загрузки данных
        parseQueue.maxConcurrentOperationCount = 1
    }
    
    deinit {
        
        // Удаляем KVO обозреватель
        parseQueue.removeObserver(self, forKeyPath: "operations.count", context: nil)
    }
    
    /// Функция обработки KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? OperationQueue == parseQueue && keyPath == "operations.count" && parseQueue.operations.count == 0 {
            NotificationCenter.default.post(name: AppDefaults.Notifications.ParseOperation.didParseAllFeeds, object: nil)
        }
    }
    
    /// Функция обновления всех существующих каналов
    func updateFeeds () {
        
        // Конфигурируем запрос к базе данных, который должен вернуть только ссылки на существующие каналы
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RssFeed.fetchRequest()
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        fetchRequest.propertiesToFetch = ["feedLink"]
        
        // Запрашиваем базу данных
        if let result = try? managedObjectContext.fetch(fetchRequest), let objects = result  as? [[String: String]] {
            
            // Получаем ссылки на существующие каналы
            let feedsLinks = objects.flatMap{ $0["feedLink"] }
            
            // Обновляем каждый существующий канал
            for feedLink in feedsLinks {
                parseFeed(URL(string: feedLink)!)
            }
        }
    }
    
    /// Функция загрузки канала
    func parseFeed(_ defaultURL: URL) {
        
        // Проверяем наличие в паралельном потоке операции загрузки канала с указанной ссылкой
        if !parseQueue.operations.contains(where: { $0.name == defaultURL.absoluteString }) {
            
            // Добавляем в параллельный поток новую операцию загрузки канала
            parseQueue.addOperation(FeedParseOperation(defaultURL))
        }
    }
}
