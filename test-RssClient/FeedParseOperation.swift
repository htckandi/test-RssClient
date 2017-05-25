//
//  FeedParseOperation.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 22.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit
import CoreData

/// Операция загрузки и обработки данных с канала
class FeedParseOperation: Operation, XMLParserDelegate {

    /// Элемент канала
    class ItemObject: NSObject {
        
        var itemTitle: String?
        var itemLink: String?
        var itemDescription: String?
        var itemPubDate: String?
    }
    
    /// Канал
    class FeedObject: NSObject {
        
        var feedTitle: String?
        var feedUri: String?
        var feedDescription: String?
        var feedLink: String?
        var feedItems = [ItemObject]()
    }
    
    /// Ссылка на канал
    var feedUrl: URL
    
    /// Обрабатываемый канал
    var feedObject: FeedObject?
    
    /// Обрабатываемый элемент канала
    var itemObject: ItemObject?
    
    /// Обрабатываемый текст
    var objectString = ""
    
    /// Обработанный канал
    lazy var _operationFeed = FeedObject()
    
    /// Параллельный контекст базы данных
    lazy var _operationMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    
    init(_ defaultFeedUrl: URL) {
        
        // Сохраняем ссылку на канал
        feedUrl = defaultFeedUrl
        
        super.init()
        
        // Сохраняем в качестве имени операции ссулку на канал с целью возможности дальнейшего поиска
        name = feedUrl.absoluteString
        
        // Переходим в главный поток
        DispatchQueue.main.async() { _ in
            
            // Публикуем уведомление о начале обработки канала
            NotificationCenter.default.post(name: AppDefaults.Notifications.ParseOperation.willParseFeed, object: nil, userInfo: ["operationName": self.name!])
        }
    }
    
    override func main() {
        
        // Отображаем индикатор активности сети
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Проверяем возможность создания парсера
        if let xmlParser = XMLParser(contentsOf: feedUrl) {
            
            // Скрываем индикатор активности сети
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Конфигурируем парсер
            xmlParser.delegate = self
            
            // Запускаем парсер
            if xmlParser.parse() {
                
                // Проверяем наличие структуры канала
                if let object = feedObject {
                
                    // Сохраняем канал
                    _operationFeed = object
                    
                    // Запускаем обновление базы данных
                    updateBase()
                }
            }
        } else {
         
            // Скрываем индикатор активности сети
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        // Переходим в главный поток
        DispatchQueue.main.async() { _ in
            
            // Публикуем уведомление о завершении обработки канала
            NotificationCenter.default.post(name: AppDefaults.Notifications.ParseOperation.didParseFeed, object: nil, userInfo: ["operationName": self.name!])
        }
    }
    
    
    // MARK: - Core Data
    
    /// Обновляет базу данных
    func updateBase() {
        
        // Конфигурируем контекст
        _operationMoc.parent = AppAssist.shared.managedObjectContext
        _operationMoc.automaticallyMergesChangesFromParent = true
        
        // Обновляем канал
        updateFeed(searchForFeed() ?? insertNewFeed())
    }
    
    /// Осуществляет поиск необходимого канала в контексте
    func searchForFeed () -> RssFeed? {
        
        // Готовим запрос к базе данных
        let fetchRequest: NSFetchRequest<RssFeed> = RssFeed.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "feedUri == %@", name!)
        
        // Ищем подобный канал в базе данных
        if let objects = try? _operationMoc.fetch(fetchRequest), let object = objects.first {
            
            // Канал найден
            return object
        }
        
        // Канал не найден
        return nil
    }
    
    /// Создаёт новый канал в контексте
    func insertNewFeed () -> RssFeed {
        
        // Вносим в контекст новый канал
        let newFeed = RssFeed(context: _operationMoc)
        newFeed.feedUri = name
        
        return newFeed
    }
    
    /// Обновляет данные канала в контексте
    func updateFeed (_ rssFeed: RssFeed) {
        
        // Обновляем информацию канала
        rssFeed.feedDescription = _operationFeed.feedDescription
        rssFeed.feedTitle = _operationFeed.feedTitle
        rssFeed.feedLink = _operationFeed.feedLink
        
        // Готовим массивы существующих элементов канала
        let itemsEntities = Array(rssFeed.feedItems as? Set<RssItem> ?? Set<RssItem>())
        
        // Готовим массивы загруженных элементов канала
        let itemsObjects = _operationFeed.feedItems
        
        // Готовим массив ссылок на существующие и новые элементы канала
        let itemsEntitiesLinks = itemsEntities.flatMap{ $0.itemLink }
        
        // Готовим предикат
        let insertPredicate = NSPredicate(format: "NOT SELF.itemLink IN %@", itemsEntitiesLinks)
        
        // Получаем новые элементы канала
        let itemsObjectsToInsert = itemsObjects.filter{ insertPredicate.evaluate(with: $0) }
        
        // Добавляем новые элементы канала в контекст
        for object in itemsObjectsToInsert {
            
            let itemEntity = RssItem(context: _operationMoc)
            itemEntity.itemFeed = rssFeed
            itemEntity.itemLink = object.itemLink
            itemEntity.itemTitle = object.itemTitle
            itemEntity.itemDescription = object.itemDescription
            itemEntity.itemPubDate = object.itemPubDate?.internetDate as NSDate?
        }
        
        // Добавляем обозреватель уведомления о завершении сохранения параллельного контекста
        NotificationCenter.default.addObserver(self, selector: #selector(mocDidSave(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: _operationMoc)
        
        // Проверяем наличие изменений в параллельном контексте
        if _operationMoc.hasChanges {
            do {
                
                // Сохраняем параллельный контекст
                try _operationMoc.save()
                
            } catch {
                // Error Handling
            }
        }
    }
    
    /// Обрабатывает уведомление о завершении сохранения параллельного контекста
    func mocDidSave(notification: Notification) {
        
        // Удаляем обозреватель уведомления о завершении сохранения параллельного контекста
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: _operationMoc)
        
        // Переходим в главный поток
        DispatchQueue.main.async() { _ in
            
            // Объединяем параллельный и главный контексты
            AppAssist.shared.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        objectString = ""
        
        switch elementName {
        case "channel", "feed":
            feedObject = FeedObject()
        case "item", "entry":
            itemObject = ItemObject()
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        objectString.append(string)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if let objectFeed = feedObject {
            
            if let objectItem = itemObject {
                
                switch elementName {
                case "item", "entry":
                    objectFeed.feedItems.append(objectItem)
                    itemObject = nil
                case "title":
                    objectItem.itemTitle = objectString.trimmed
                case "description":
                    objectItem.itemDescription = objectString.trimmed
                case "link":
                    objectItem.itemLink = objectString.trimmed
                case "pubDate":
                    objectItem.itemPubDate = objectString.trimmed
                default:
                    break
                }
                
            } else {
                
                switch elementName {
                case "title":
                    objectFeed.feedTitle = objectString.trimmed
                case "description":
                    objectFeed.feedDescription = objectString.trimmed
                case "link":
                    objectFeed.feedLink = objectString.trimmed
                default:
                    break
                }
            }
        }
    }
}
