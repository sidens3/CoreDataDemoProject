//
//  StorageManager.swift
//  CoreDataDemo
//
//  Created by Михаил Зиновьев on 08.12.2021.
//

import Foundation
import CoreData

enum StorageError: Error {
    case noData
}

class StorageManager {
    
    static let shared = StorageManager()
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private init() {}
}

//MARK: Actions
extension StorageManager {
    
    func fetchData(completion: (Result<[Task], StorageError>) -> Void ) {
        let context = persistentContainer.viewContext
        let fetchRequest = Task.fetchRequest()
        
        do {
            let taskList = try context.fetch(fetchRequest)
            completion(.success(taskList))
        } catch {
            completion(.failure(.noData))
        }
    }
    
    func save(with taskName: String, and taskList: [Task], completion: () -> Void ) {
        let context = persistentContainer.viewContext
        let task = Task(context: context)
        var newTaskList = taskList
        task.title = taskName
        newTaskList.append(task)
        saveContext()
        completion()
    }
    
    func delete(task: Task, completion: () -> Void) {
        let context = persistentContainer.viewContext
    
        context.delete(task)
        saveContext()
        completion()
    }
    
    // MARK: - Core Data Saving support
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
