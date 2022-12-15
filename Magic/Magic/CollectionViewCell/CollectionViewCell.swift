//
//  CollectionViewCell.swift
//  Magic
//
//  Created by Mikolaj Uroda on 11/12/2022.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var photoView: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

