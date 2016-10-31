//
//  BooksTableViewController
//  BookSearch
//
//  Created by Guillermo Varela on 10/30/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit
import CoreData

protocol BooksHolderProtocol {
    func addBook(_ book: Book)
    func findBook(isbn: String) -> Book?
}

class BooksTableViewController: UITableViewController, BooksHolderProtocol {

    let reuseIdentifier = "reuseIdentifier"
    var context: NSManagedObjectContext? = nil
    var books = [Book]()

    @IBOutlet weak var isbnTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        let booksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BookEntity")
        do {
            let fetchedBooks = try self.context?.fetch(booksFetch) as! [BookEntity]
            for fetchedBook in fetchedBooks {
                var book = Book()
                book.isbn = fetchedBook.value(forKey: "isbn") as? String
                book.title = fetchedBook.value(forKey: "title") as? String
                if let authors = fetchedBook.value(forKey: "authors") as! String? {
                    book.authors = authors.components(separatedBy: ",")
                }
                if let coverUrl = fetchedBook.value(forKey: "coverUrl") as! String? {
                    book.coverUrl = URL(string: coverUrl)
                }
                if let cover = fetchedBook.value(forKey: "cover") as! Data? {
                    book.cover = UIImage(data: cover)
                }
                self.books.append(book)
            }
        } catch {
            print("Failed to fetch books: \(error)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Libros Encontrados"
    }

    // MARK: - Books Holder Protocol
    func addBook(_ book: Book) {
        if !self.books.contains(book) {
            self.books.append(book)

            let newBookEntity = NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: self.context!)
            newBookEntity.setValue(book.isbn, forKey: "isbn")
            newBookEntity.setValue(book.title, forKey: "title")
            if book.authors != nil && (book.authors?.count)! > 0 {
                newBookEntity.setValue(book.authors?.joined(separator: ","), forKey: "authors")
            }
            if book.coverUrl != nil {
                newBookEntity.setValue(book.coverUrl?.absoluteString, forKey: "coverUrl")
            }
            if book.cover != nil {
                newBookEntity.setValue(UIImagePNGRepresentation(book.cover!), forKey: "cover")
            }
            do {
                try self.context?.save()
            } catch {
            }
        }
    }

    func findBook(isbn: String) -> Book? {
        let result = self.books.first(where:{$0.isbn == isbn})
        return result
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = books[indexPath.item].title
        return cell
    }

    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "bookDetails", sender: sender)
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

    /*
    // MARK: - Navigation
    */

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationViewController = segue.destination as! BookViewController
        destinationViewController.booksHolderDelegate = self
        if let selectedRow = tableView.indexPathForSelectedRow {
            destinationViewController.currentBook = books[selectedRow.item]
        }
    }
}
