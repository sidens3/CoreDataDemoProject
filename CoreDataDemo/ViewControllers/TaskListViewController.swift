//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 06.12.2021.
//

import UIKit

class TaskListViewController: UITableViewController {
    private let storageManager = StorageManager.shared
    
    private var taskList: [Task] = []
    private let cellID = "task"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        tableView.reloadData()
    }

    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        showAlert(title: "New task", message: "What do you want to do?")
    }
}

//MARK: - Actions with storage
extension TaskListViewController {
    
    private func save(_ taskName: String) {
        storageManager.save(with: taskName, and: taskList) {
            updateData()
            let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
            tableView.insertRows(at: [cellIndex], with: .automatic)
        }
    }
    
    private func update(_ updatedTask: Task?, newValue: String){
        guard let safeUpdatedTask = updatedTask else { return }
        safeUpdatedTask.title = newValue
        
        storageManager.saveContext()
        tableView.reloadData()
    }
    
    private func delete(by indexPath: IndexPath) {
        storageManager.delete(task: taskList[indexPath.row]) {
            updateData()
            let cellIndex = IndexPath(row: indexPath.row , section: 0)
            tableView.deleteRows(at: [cellIndex], with: .automatic)
        }
    }
}

//MARK: - Private
extension TaskListViewController {
    private func updateData() {
        storageManager.fetchData { result in
            switch result {
                
            case .success( let tasks):
                taskList = tasks
            case .failure( let error):
                showAlert(for: error)
            }
        }
    }
    
    private func showAlert(for error: StorageError) {
        var errorText = "unknown error"
        
        switch error {
        case .noData:
            errorText = "No data"
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Failed",
                message: errorText,
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String, existedTask: Task? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            if existedTask == nil  {
                self.save(task)
            } else {
                self.update(existedTask, newValue: task)
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = title
            textField.text = existedTask?.title ?? ""
            
        }
        present(alert, animated: true)
    }
    
    private func makeDeleteContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .destructive, title: "Delete") { (action, swipeButtonView, completion) in
            self.delete(by: indexPath)
            completion(true)
        }
    }
}

//MARK: TableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
}

//MARK: TableViewDelegate
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [ makeDeleteContextualAction(forRowAt: indexPath) ])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        showAlert(title: "Edit task", message: "What do you want to do?", existedTask: task)
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
