//
//  SearchTableViewController.swift
//  BookSearch
//
//  Created by Guillermo Varela on 10/30/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController {

    let reuseIdentifier = "reuseIdentifier"
    let openLibraryEndpointComponents = NSURLComponents()
    var books = [Book]()
    var dataTask: URLSessionDataTask?

    @IBOutlet weak var isbnTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        openLibraryEndpointComponents.scheme = "https";
        openLibraryEndpointComponents.host = "openlibrary.org";
        openLibraryEndpointComponents.path = "/api/books";
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Libros Encontrados"
    }

    @IBAction func searchButtonClicked(_ sender: UIBarButtonItem) {
        if let isbn = isbnTextField.text {
            if isbn.isEmpty {
                showError("ISBN inválido.")
            } else {
                findBook(isbn)
            }
        } else {
            showError("ISBN inválido.")
        }
    }

    private func showError(_ message : String) -> Void {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }

    private func findBook(_ isbn: String) {
        if dataTask != nil && dataTask?.state == .running {
            return
        }
        let jscmdQuery = URLQueryItem(name: "jscmd", value: "data")
        let formatQuery = URLQueryItem(name: "format", value: "json")
        let bibkeysQuery = URLQueryItem(name: "bibkeys", value: "ISBN:" + isbn)
        openLibraryEndpointComponents.queryItems = [jscmdQuery, formatQuery, bibkeysQuery]

        let urlRequest = URLRequest(url: openLibraryEndpointComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

                // check for errors
                guard error == nil else {
                    if error?.localizedDescription != "cancelled" {
                        self.showError("Error consultando, por favor verifica tu conexión a Internet.")
                    }
                    return
                }
                // check for data
                if let data = data {
                    do {
                        guard let book = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                            self.showError("Error procesando la respuesta del servidor.")
                            return
                        }
                        if book.count == 0 {
                            self.showError("No se encontró un libro con ese ISBN.")
                        } else {
                            let bookFound = self.buildBook(book, isbn)
                            if self.books.contains(bookFound) {
                                self.showError("Búsqueda repetida.")
                            } else {
                                self.books.append(bookFound)
                                self.tableView.reloadData()
                                self.isbnTextField.text = nil
                                self.performSegue(withIdentifier: "bookDetails", sender: bookFound)
                            }
                        }
                    } catch  {
                        self.showError("Error procesando la respuesta del servidor.")
                    }
                } else {
                    self.showError("No se obtuvo una respuesta del servidor, por favor intenta de nuevo más tarde.")
                }
            }
        })
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask?.resume()
    }

    private func buildBook(_ book : [String : AnyObject]?, _ isbn : String) -> Book {
        var bookObject = Book()
        bookObject.isbn = isbn
        if let bookContent = book?["ISBN:" + isbn] as! [String : AnyObject]? {
            bookObject.title = bookContent["title"] as? String
            if let authors = bookContent["authors"] as! [[String : String]]? {
                bookObject.authors = authors.map({$0["name"]!})
            }
            if let cover = bookContent["cover"] as! [String : AnyObject]? , let coverUrl = cover["medium"] as! String? {
                bookObject.coverUrl = URL(string: coverUrl)!
            }
        }
        return bookObject
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
        if let book = sender as? Book {
            destinationViewController.book = book
        } else if let selectedRow = tableView.indexPathForSelectedRow {
            destinationViewController.book = books[selectedRow.item]
        }
    }
}
