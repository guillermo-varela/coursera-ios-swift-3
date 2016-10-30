//
//  BookViewController.swift
//  BookSearch
//
//  Created by Guillermo Varela on 10/30/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import UIKit

class BookViewController: UIViewController {

    var book: Book!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var noCoverLabel: UILabel!
    @IBOutlet weak var coverUIImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        titleLabel.text = book.title
        authorsLabel.text = book.authors?.joined(separator: ", ")
        if let coverUrl = book.coverUrl {
            downloadCover(coverUrl)
            noCoverLabel.isHidden = true
        } else {
            noCoverLabel.isHidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
