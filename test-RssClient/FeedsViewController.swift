//
//  FeedsViewController.swift
//  test-RssClient
//
//  Created by Сергей Табунщиков on 13.05.17.
//  Copyright © 2017 Sergey Tabunshikov. All rights reserved.
//

import UIKit
import CoreData

class FeedsViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    /// Контекст базы данных
    let managedObjectContext = AppAssist.shared.managedObjectContext
    
    /// Контроллер базы данных
    var _fetchedResultsController: NSFetchedResultsController<RssFeed>?
    
    /// Search controller to help us with filtering
    var searchController: UISearchController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Конфигурируем контроллер поиска
        searchController = UISearchController(searchResultsController: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController"))
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        // Конфигурируем текущий контроллер
        definesPresentationContext = true
        
        // Конфигурируем таблицу
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableHeaderView = searchController.searchBar
        
        // Добавляем тестовые каналы
        AppAssist.shared.parseFeed(URL(string: "https://news.rambler.ru/rss/head/")!)
        AppAssist.shared.parseFeed(URL(string: "https://news.yandex.ru/index.rss")!)
        AppAssist.shared.parseFeed(URL(string: "https://news.rambler.ru/rss/world/")!)
        AppAssist.shared.parseFeed(URL(string: "https://lenta.ru/rss")!)
        AppAssist.shared.parseFeed(URL(string: "https://news.yandex.ru/gadgets.rss")!)
        
    }
    
    deinit {
        
        // Удаляем обозреватели уведомлений
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Функция добавления нового канала из буфера обмена
    @IBAction func addNewFeed(_ sender: UIBarButtonItem) {
        
        // Проверяем наличие ссылки в буфере обмена
        if let objectLink = UIPasteboard.general.string, let objectUrl = URL(string: objectLink) {
            
            // Буфер обмена содержит корректную ссылку
            // Готовим запрос к базе данных
            let fetchRequest: NSFetchRequest<RssFeed> = RssFeed.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "feedUri == %@", objectUrl.absoluteString)
            
            // Проверяем наличие подобного канала в базе данных
            if let object = try? managedObjectContext.count(for: fetchRequest), object == 0 {
                
                // Подобного канала нет в базе данных
                // Готовим информационный контроллер с запросом на добавление канала
                let alertController = UIAlertController(title: nil, message: "Pasteboard contains link", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Add feed", style: .default, handler: { _ in AppAssist.shared.parseFeed(objectUrl) }))
                
                // Отображаем информационный контроллер
                present(alertController, animated: true, completion: nil)
                
            } else {
                
                // Подобного канала нет в базе данных
                // Готовим информационный контроллер с сообщением о существовании подобного канала в базе данных
                let alertController = UIAlertController(title: nil, message: "Such feed exists", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                // Отображаем информационный контроллер
                present(alertController, animated: true, completion: nil)
            }
            
        } else {
            
            // Буфер обмена не содержит корректную ссылку
            // Готовим информационный контроллер с сообщением об отсутствии в буфере обмена корректной ссылки
            let alertController = UIAlertController(title: nil, message: "There is no link in pasteboard\nCopy RSS link to pasteboard and try again", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            // Отображаем информационный контроллер
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // Принудительное обновление существующих каналов пользователем
    @IBAction func handleRefreshControl(_ sender: Any) {
        
        // Обновляем все существующие каналы
        AppAssist.shared.updateFeeds()
        
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

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Удаляем канал из базы данных
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

    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: - UISearchControllerDelegate
    
    func presentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        if let controller = searchController.searchResultsController as? SearchViewController {
            controller.searchString = searchController.searchBar.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }
    
    
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
