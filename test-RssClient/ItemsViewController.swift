//
//  ItemsViewController.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 22.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

class ItemsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Главный контекст
    let managedObjectContext = AppAssist.shared.managedObjectContext
    
    // Контроллер контекста
    var _fetchedResultsController: NSFetchedResultsController<RssItem>?
    
    // Текущий канал
    var rssFeed: RssFeed!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Конфигурируем таблицу
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    /// Принудительное обновление текущего канала пользователем
    @IBAction func handleRefreshControl(_ sender: Any) {
        
        // Обновляем текущий канал
        AppAssist.shared.parseFeed(URL(string: rssFeed.feedLink!)!)
        
        // Создаём задержку главного потока исключительно с целью эффекта задержки интерфейса пользователя
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            
            // Скрываем индикатор обновления
            self.refreshControl?.endRefreshing()
        })
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemsCell", for: indexPath) as! ItemsViewCell
        cell.rssItem = fetchedResultsController.object(at: indexPath)
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Получаем объект элемента канала
        let object = fetchedResultsController.object(at: indexPath)
        
        // Проверяем наличие ссылки в элементе канала
        if let objectLink = object.itemLink, let objectURL = URL(string: objectLink) {
            
            // Открываем Safari с указанной ссылкой
            let safariController = SFSafariViewController(url: objectURL)
            present(safariController, animated: true, completion: nil)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Удаляем элемент канала из контекста
            managedObjectContext.delete(fetchedResultsController.object(at: indexPath))
        }
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<RssItem> {
        
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        
        let fetchRequest: NSFetchRequest<RssItem> = RssItem.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "itemPubDate", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "itemFeed == %@", rssFeed)
        
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
