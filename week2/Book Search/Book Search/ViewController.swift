//
//  ViewController.swift
//  Book Search
//
//  Created by Guillermo Varela on 10/22/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate {

    let openLibraryEndpointComponents = NSURLComponents()
    var dataTask: URLSessionDataTask?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var noCoverLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        openLibraryEndpointComponents.scheme = "https";
        openLibraryEndpointComponents.host = "openlibrary.org";
        openLibraryEndpointComponents.path = "/api/books";
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let isbn = searchBar.text {
            if isbn.isEmpty {
                showError("ISBN inválido.")
            } else {
                findBook(isbn: isbn)
            }
        } else {
            showError("ISBN inválido.")
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if dataTask != nil && dataTask?.state == .running {
            dataTask?.cancel()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }

    private func findBook(isbn: String) {
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
                            self.showBook(book, isbn)
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
        titleLabel.text = ""
        authorsLabel.text = ""
        coverImageView.image = nil
        noCoverLabel.isHidden = true
    }

    private func showError(_ message : String) -> Void {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }

    private func showBook(_ book : [String : AnyObject]?, _ isbn : String) -> Void {
        if let bookContent = book?["ISBN:" + isbn] as! [String : AnyObject]? {
            self.titleLabel.text = bookContent["title"] as! String?
            if let authors = bookContent["authors"] as! [[String : String]]? {
                self.authorsLabel.text = authors.map({$0["name"]!}).joined(separator: ", ")
            }
            if let cover = bookContent["cover"] as! [String : AnyObject]? , let coverUrl = cover["medium"] as! String? {
                downloadCover(coverUrl)
            } else {
                self.noCoverLabel.isHidden = false
            }
        }
    }

    private func downloadCover(_ url : String) -> Void {
        let urlObject = URL(string: url)
        let urlRequest = URLRequest(url: urlObject!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                // check for errors
                guard error == nil else {
                    if error?.localizedDescription != "cancelled" {
                        self.showError("Error descargando la portada, por favor verifica tu conexión a Internet.")
                    }
                    return
                }
                // check for data
                if let data = data {
                    self.coverImageView.image = UIImage(data: data)
                }
            }
        }).resume()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
}

