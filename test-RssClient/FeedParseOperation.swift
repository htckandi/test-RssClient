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
        var feedLink: String?
        var feedDescription: String?
        var feedItems = [ItemObject]()
    }
    
    /// Ссылка на канал
    var feedURL: URL
    
    /// Обрабатываемый элемент канала
    var itemObject: ItemObject?
    
    /// Обрабатываемый канал
    var feedObject: FeedObject?
    
    /// Текст при обработке канала
    var rssString = ""
    
    /// Временный обрабатываемый канал
    lazy var _operationFeed = FeedObject()
    
    /// Временный контекст базы данных
    lazy var _operationMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    
    init(_ defaultFeedUrl: URL) {
        
        // Сохраняем ссылку на канал
        feedURL = defaultFeedUrl
        
        super.init()
        
        // Сохраняем в качестве имени операции ссулку на канал с целью возможности дальнейшего поиска
        name = feedURL.absoluteString
    }
    
    deinit {
        
        // Удаляем обозреватели уведомлений
        NotificationCenter.default.removeObserver(self)
    }
    
    override func main() {
        
        // Проверяем возможность создания парсера
        if let xmlParser = XMLParser(contentsOf: feedURL) {
            
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
        }
    }
    
    
    // MARK: - Core Data
    
    /// Обновляем базу данных
    func updateBase() {
        
        // Конфигурируем контекст
        _operationMoc.parent = AppAssist.shared.managedObjectContext
        _operationMoc.automaticallyMergesChangesFromParent = true
        
        // Обновляем канал
        updateFeed(searchForFeed() ?? insertNewFeed())
    }
    
    /// Осуществляет поиск в базе данных необходимого канала
    func searchForFeed () -> RssFeed? {
        
        let fetchRequest: NSFetchRequest<RssFeed> = RssFeed.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "feedLink == %@", _operationFeed.feedLink!)
        
        if let object = try? _operationMoc.fetch(fetchRequest).first {
            return object
        }
        
        return nil
    }
    
    /// Создаёт в базе данных новый канал
    func insertNewFeed () -> RssFeed {
        
        let feedEntity = RssFeed(context: _operationMoc)
        feedEntity.feedLink = _operationFeed.feedLink
        
        return feedEntity
    }
    
    /// Обновляет информацию канала в базе данных
    func updateFeed (_ rssFeed: RssFeed) {
        
        // Обновляем информацию канала
        rssFeed.feedDescription = _operationFeed.feedDescription
        rssFeed.feedTitle = _operationFeed.feedTitle
        
        // Получаем наборы существующих и загруженных объектов новостей
        let itemsEntities = Array(rssFeed.feedItems as? Set<RssItem> ?? Set<RssItem>())
        let itemsObjects = _operationFeed.feedItems
        
        // Получаем наборы ссылок на существующие и новые новости
        let itemsEntitiesLinks = itemsEntities.flatMap{ $0.itemLink }
        
        // Готовим предикаты
        let insertPredicate = NSPredicate(format: "NOT SELF.itemLink IN %@", itemsEntitiesLinks)
        
        // Получаем фильтрованные массивы новостей
        let itemsObjectsToInsert = itemsObjects.filter{ insertPredicate.evaluate(with: $0) }
        
        // Добавляем новые новости
        for object in itemsObjectsToInsert {
            
            let itemEntity = RssItem(context: _operationMoc)
            itemEntity.itemFeed = rssFeed
            itemEntity.itemLink = object.itemLink
            itemEntity.itemTitle = object.itemTitle
            itemEntity.itemDescription = object.itemDescription
            itemEntity.itemPubDate = object.itemPubDate?.internetDate as NSDate?
        }
        
        // Добавляем обозреватель уведомления о завершении сохранения контекста
        NotificationCenter.default.addObserver(self, selector: #selector(mocDidSave(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: _operationMoc)
        
        // Проверяем наличие зменений в контексте
        if _operationMoc.hasChanges {
            do {
                
                // Сохраняем контекст
                try _operationMoc.save()
                
            } catch {
                // Error Handling
            }
        }
    }
    
    /// Функция обработки уведомления о завершении сохранения контекста
    func mocDidSave(notification: Notification) {
        
        // Переходим в главный поток
        DispatchQueue.main.async() { _ in
            
            // Объединяем контекст операции и главный контекст
            AppAssist.shared.managedObjectContext.mergeChanges(fromContextDidSave: notification)
            
            // Публикуем уведомление о завершении загрузки данных с канала вместе с полученными данными
            NotificationCenter.default.post(name: AppDefaults.Notifications.ParseOperation.didParse, object: nil, userInfo: ["operationName": self.name!])
        }
    }
    
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        rssString = ""
        
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
        rssString.append(string)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if let objectRssFeed = feedObject {
            
            if let objectRssItem = itemObject {
                
                switch elementName {
                case "item", "entry":
                    objectRssFeed.feedItems.append(objectRssItem)
                    itemObject = nil
                case "title":
                    objectRssItem.itemTitle = rssString.trimmed
                case "description":
                    objectRssItem.itemDescription = rssString.trimmed
                case "link":
                    objectRssItem.itemLink = rssString.trimmed
                case "pubDate":
                    objectRssItem.itemPubDate = rssString.trimmed
                default:
                    break
                }
                
            } else {
                
                switch elementName {
                case "title":
                    objectRssFeed.feedTitle = rssString.trimmed
                case "description":
                    objectRssFeed.feedDescription = rssString.trimmed
                case "link":
                    objectRssFeed.feedLink = rssString.trimmed
                default:
                    break
                }
            }
        }
    }
}
