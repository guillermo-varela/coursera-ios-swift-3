//
//  Book.swift
//  BookSearch
//
//  Created by Guillermo Varela on 10/30/16.
//  Copyright © 2016 Guillermo Varela. All rights reserved.
//

import Foundation
import UIKit

struct Book: Equatable {
    var isbn: String?
    var title: String?
    var authors: [String]?
    var coverUrl: URL?
    var cover: UIImage?

    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.isbn == rhs.isbn
    }
}
