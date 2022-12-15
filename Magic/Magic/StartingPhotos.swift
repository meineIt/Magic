//
//  StartingPhotos.swift
//  Magic
//
//  Created by Mikolaj Uroda on 11/12/2022.
//

//import Foundation
import UIKit

class StartingPhotos {
    
    let context = CIContext()
    
    lazy var objectsArray = [
        TableViewCellModel(
            photos: [
                [CVCM2(userImage: UIImage(named: "wall_8")!, filterName: "Original"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_1")!, filterName: "CIPhotoEffectTransfer"), filterName: "Transfer"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_2")!, filterName: "CIPhotoEffectTonal"), filterName: "Tonal"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_3")!, filterName: "CIPhotoEffectProcess"), filterName: "Process"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_4")!, filterName: "CIPhotoEffectNoir"), filterName: "Noir"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_5")!, filterName: "CIPhotoEffectFade"), filterName: "Fade"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_6")!, filterName: "CIPhotoEffectInstant"), filterName: "Instant"),
                 CVCM2(userImage: modifyImage(input: UIImage(named: "wall_7")!, filterName: "CIPhotoEffectMono"), filterName: "Mono")]
            ]),
    ]
    
    func modifyImage(input: UIImage, filterName: String) -> UIImage {
        
        let selectedFilter = CIFilter(name: filterName)!
        selectedFilter.setValue(CIImage(image: input), forKey: kCIInputImageKey)
        
        if let cgimg = context.createCGImage(selectedFilter.outputImage!, from: selectedFilter.outputImage!.extent) {
            return UIImage(cgImage: cgimg)
        } else {
            return input
        }
    }
}
