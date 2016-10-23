//
//  ViewController.swift
//  Book Search
//
//  Created by Guillermo Varela on 10/22/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var bookTextView: UITextView!

    let openLibraryEndpointComponents = NSURLComponents()
    var dataTask: URLSessionDataTask?

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

        let urlRequest = NSURLRequest(url: openLibraryEndpointComponents.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        dataTask = session.dataTask(with: urlRequest as URLRequest, completionHandler: { (data, response, error) in
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
                    let dataString = String(data: data, encoding: .utf8)
                    if dataString == "{}" {
                        self.showError("No se encontró un libro con ese ISBN.")
                    } else {
                        self.bookTextView.text = dataString
                    }
                } else {
                    self.showError("No se obtuvo una respuesta del servidor, por favor intenta de nuevo más tarde.")
                }
            }
        })
        self.bookTextView.text = ""
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask?.resume()
    }

    private func showError(_ message : String) {
        let alertController = UIAlertController(title: "Ups", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in}))
        self.present(alertController, animated: true, completion: nil)
    }
}

