//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    var itemArray: [Item] = []
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    let fileDataPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    // Reference to the context in AppDelegate by using singletones
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        For Custom Cell
        //        tableView.separatorStyle = .none
        //        tableView.register(UINib(nibName: K.customCellNibName, bundle: nil), forCellReuseIdentifier: K.customCellIdentifier)
        
        self.hideKeyboardWhenTappedAround()
        
        navItem.title = selectedCategory?.name
    }
    
    
    //MARK: - TableViewDelegate methods
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
        //        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItem(indexPath: indexPath)
            saveItems()
        }
    }
    
    
    //MARK: - TableViewDataSource methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.itemCellIdentifier, for: indexPath);
        let item = itemArray[indexPath.row];
        
        cell.textLabel?.text = item.title;
        cell.accessoryType = item.done ? .checkmark : .none
        return cell;
    }
    
    //MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert);
        
        var textField = UITextField();
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            self.itemArray.append(newItem)
            self.saveItems()
        }
        
        // 1st happens this
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create New Item"
            textField = alertTextField
        }
        
        // 2nd happens this
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - Model Manipulation Methods
    
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), searchPredicates: [NSPredicate]  = [], sortDescriptors: [NSSortDescriptor] = []) {
        
        let matchPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        let predicates = [matchPredicate] + searchPredicates
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = sortDescriptors
        
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("An error occured in 'loadItems' ⚠️")
        }
        tableView.reloadData()
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("An error occured in 'saveItems' ⚠️")
        }
        tableView.reloadData()
    }
    
    func deleteItem(indexPath: IndexPath) {
        context.delete(itemArray[indexPath.row])
        itemArray.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
}


//MARK: - UISearchBarDelegate

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if searchBar.text?.count != 0 {
            let request: NSFetchRequest<Item> = Item.fetchRequest()
            
            let titleSearchPredicate: NSPredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
            let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "title", ascending: true)]
            
            loadItems(searchPredicates: [titleSearchPredicate], sortDescriptors: sortDescriptors)
            //            self.dismissKeyboard()
        } else {
            loadItems()
            //            self.dismissKeyboard()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
        }
    }
    
}


extension TodoListViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
