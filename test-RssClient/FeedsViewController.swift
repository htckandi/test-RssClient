//
//  FeedsViewController.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 13.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit
import CoreData

class FeedsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Контекст базы данных
    let managedObjectContext = AppAssist.shared.managedObjectContext
    
    // Контроллер базы данных
    var _fetchedResultsController: NSFetchedResultsController<RssFeed>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Добавляем обозреватели уведомлений об этапах выполнения операции загрузки канала
        NotificationCenter.default.addObserver(self, selector: #selector(parserDidParseFeed(notification:)), name: AppDefaults.Notifications.ParseOperation.didParseAllFeeds, object: nil)
        
        // Конфигурируем таблицу
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Добавляем тестовые каналы
        AppAssist.shared.parseFeed(URL(string: "https://news.rambler.ru/rss/head/")!)
        AppAssist.shared.parseFeed(URL(string: "https://news.yandex.ru/index.rss")!)
        AppAssist.shared.parseFeed(URL(string: "https://news.rambler.ru/rss/world/")!)
        AppAssist.shared.parseFeed(URL(string: "https://lenta.ru/rss")!)
        AppAssist.shared.parseFeed(URL(string: "http://feeds.bbci.co.uk/news/rss.xml?edition=int#")!)
    }
    
    deinit {
        
        // Удаляем обозреватели уведомлений
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Обрабатываем уведомление о завершении операции загрузки данных с канала
    func parserDidParseFeed (notification: Notification) {
        
        // Проверяем наличие идикатора обновления на экране
        if refreshControl?.isRefreshing == true {
            
            // Скрываем индикатор обновления
            refreshControl?.endRefreshing()
            
            // Разблокируем интерфейс пользователя
            tableView.isUserInteractionEnabled = true
        }
    }
    
    // Функция обработки принудительного обновления существующих каналов
    @IBAction func handleRefreshControl(_ sender: Any) {
        
        // Блокируем интерфейс пользователя
        tableView.isUserInteractionEnabled = false
        
        // Обновляем все существующие каналы
        AppAssist.shared.updateFeeds()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedsCell", for: indexPath) as! FeedsViewCell
        cell.rssFeed = fetchedResultsController.object(at: indexPath)
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let controller = segue.destination as? ItemsViewController, let indexPath = tableView.indexPathForSelectedRow {
            controller.rssFeed = fetchedResultsController.object(at: indexPath)
        }
    }
 
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<RssFeed> {
        
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        
        let fetchRequest: NSFetchRequest<RssFeed> = RssFeed.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "feedTitle", ascending: true)]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
