//
//  BookViewController.swift
//  BookSearch
//
//  Created by Guillermo Varela on 10/30/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit

class BookViewController: UIViewController {

    var currentBook: Book!
    var booksHolderDelegate: BooksHolderProtocol!
    var dataTask: URLSessionDataTask?
    let openLibraryEndpointComponents = NSURLComponents()

    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var isbnLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var noCoverLabel: UILabel!
    @IBOutlet weak var coverUIImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        openLibraryEndpointComponents.scheme = "https";
        openLibraryEndpointComponents.host = "openlibrary.org";
        openLibraryEndpointComponents.path = "/api/books";
    }

    override func viewWillAppear(_ animated: Bool) {
        if currentBook != nil {
            showBook(currentBook, true)
        } else {
            searchLabel.isHidden = false
            searchTextField.isHidden = false
            resultsLabel.isHidden = false
            isbnLabel.text = nil
            titleLabel.text = nil
            authorsLabel.text = nil
            coverUIImageView.image = nil
            noCoverLabel.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchBook(_ sender: UITextField) {
        if let isbn = sender.text {
            if isbn.isEmpty {
                showError("ISBN inválido.")
            } else {
                findBook(isbn)
            }
        } else {
            showError("ISBN inválido.")
        }
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
                            self.currentBook = self.buildBook(book, isbn)
                            self.showBook(self.currentBook, false)
                            self.searchTextField.text = nil
                            self.booksHolderDelegate.addBook(self.currentBook)
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

    private func showBook(_ book: Book, _ hideSearch: Bool) -> Void {
        if hideSearch {
            searchLabel.isHidden = true
            searchTextField.isHidden = true
            resultsLabel.isHidden = true
        }
        isbnLabel.text = book.isbn
        titleLabel.text = book.title
        authorsLabel.text = book.authors?.joined(separator: ", ")
        if let coverUrl = book.coverUrl {
            downloadCover(coverUrl)
            noCoverLabel.isHidden = true
        } else {
            noCoverLabel.isHidden = false
            self.coverUIImageView.image = nil
        }
    }

    private func downloadCover(_ url : URL) -> Void {
        let urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                // check for errors
                guard error == nil else {
                    self.showError("Error descargando la portada, por favor verifica tu conexión a Internet.")
                    self.coverUIImageView.image = nil
                    return
                }
                // check for data
                if let data = data {
                    self.coverUIImageView.image = UIImage(data: data)
                }
            }
        }).resume()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    private func showError(_ message : String) -> Void {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}
