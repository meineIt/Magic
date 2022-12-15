//
//  ViewController.swift
//  Magic
//
//  Created by Mikolaj Uroda on 10/12/2022.
//

import UIKit
import CoreImage

class ViewController: UIViewController, CollectionViewCellDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var imageView: UIImageView!
    
    // yellow buttons
    @IBOutlet var effectsButton: UIButton!
    @IBOutlet var rgbButton: UIButton!
    
    // sliders
    @IBOutlet var firstSlider: UISlider!
    @IBOutlet var secondSlider: UISlider!
    @IBOutlet var thirdSlider: UISlider!
    
    // labels
    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var secondLabel: UILabel!
    @IBOutlet var thirdLabel: UILabel!
    
    var colorsArray = StartingPhotos()
    var tappedCell: CVCM2!

    var context = CIContext()
    var selectedFilter: CIFilter!
    var setFilterName = String()
    
    // The album of all modified images by user. When user tap undo-button then the previously saved image is shown and the last is deleted.
    var userCreatedImagesAlbum: [UIImage] = [UIImage]() { didSet {
        if #available(iOS 16.0, *) {
            if userCreatedImagesAlbum.count > 1 {
                navigationItem.leftBarButtonItem?.isHidden = false
            } else {
                navigationItem.leftBarButtonItem?.isHidden = true
            }
        } } }
    
    // constant filters
    let allFilters = ["Original", "CIPhotoEffectTransfer", "CIPhotoEffectTonal", "CIPhotoEffectProcess", "CIPhotoEffectNoir", "CIPhotoEffectFade", "CIPhotoEffectInstant", "CIPhotoEffectMono"]
    
    // adjustable filters
    let effectDict = ["Blur" : "CIGaussianBlur",
        "Bump Distortion" : "CIBumpDistortion",
        "Pixellate" : "CIPixellate",
        "Sepia" : "CISepiaTone",
        "Twirl Distortion" : "CITwirlDistortion",
        "Mask" : "CIUnsharpMask",
        "Vignette" : "CIVignette"]
    
    
    var userImageObjectsArr: [TableViewCellModel]!
    
    // every time user upload a photo then this photo is filtered and shown in horizontal collectionView
    var selectedImage: UIImage! = UIImage(named: "toy") { didSet {
        userImageObjectsArr = [
            TableViewCellModel(
                photos: [
                     [CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[0]), filterName: "Original"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[1]), filterName: "Transfer"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[2]), filterName: "Tonal"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[3]), filterName: "Process"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[4]), filterName: "Noir"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[5]), filterName: "Fade"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[6]), filterName: "Instant"),
                     CVCM2(userImage: modifyImage(input: selectedImage, filterName: allFilters[7]), filterName: "Mono")]
                ]),
            ]
        tableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        view.backgroundColor = .black
        hideLabelAndSliders(hide: true)
        
        effectsButton.layer.cornerRadius = 8
        rgbButton.layer.cornerRadius = 8
        
        // sliders value
        firstSlider.value = 0.0
        secondSlider.value = 0.0
        thirdSlider.value = 0.0
        
        // set tableView properties
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.gray
        tableView.separatorStyle = .none
        
        // register the xib for tableview cell
        let cellNib = UINib(nibName: "TableViewCell", bundle: nil)
        self.tableView.register(cellNib, forCellReuseIdentifier: "tableviewcellid")

        imageView.contentMode = .scaleAspectFit
        
        // add navBar buttons (space between these buttons is set in appDelegate)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undoButtonPressed))
        
        let addButton = UIBarButtonItem(title: "Add photo", style: .plain, target: self, action: #selector(pickUpPictureFromSource))
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveToGallery))
        navigationItem.rightBarButtonItems = [addButton, saveButton]

        // get notification from TableViewCell when user press collectionView. Sends info to collectionViewPressed() which puts the tapped photo inside imageView
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(ViewController.collectionViewPressed),
                                       name: .sentFilterNumberNotification,
                                       object: nil)
    }

    
    // MARK: - Changes visible on screen
    
    // when we got notification from TableViewCell then the imageView.image is being changed
    @objc func collectionViewPressed(_ notification: NSNotification) {
        
        guard selectedImage != nil else { return }
        
        hideLabelAndSliders(hide: true)
        
        for i in [firstSlider, secondSlider, thirdSlider] { i?.isHidden = true }
        
        if let safeSentFilterNumber = notification.object as? Int {
            self.imageView.image = self.modifyImage(input: self.selectedImage, filterName: self.allFilters[safeSentFilterNumber])
            saveImageChanges()
        }
    }
    
    
    // makes sliders and labels visible or not - depends on "hide" value
    func hideLabelAndSliders(hide : Bool) {
        
        if hide {
            firstLabel.text = "Value"
            firstSlider.tintColor = .yellow
        } else {
            firstLabel.text = "Red"
            firstSlider.tintColor = UIColor(hex: Constants.red)
            secondSlider.tintColor = UIColor(hex: Constants.green)
            thirdSlider.tintColor = UIColor(hex: Constants.blue)
        }
        
        // labels
        firstLabel.isHidden = hide
        secondLabel.isHidden = hide
        thirdLabel.isHidden = hide
        
        // sliders
        for slider in [firstSlider, secondSlider, thirdSlider] {
            slider?.isHidden = hide
            slider?.value = 0.0
        }

    }
    
    
    // shows the previous photo from userCreatedImagesAlbum (Array)
    @objc func undoButtonPressed() {
        // cacheImages = number of saved photos
        let cacheImages:Int = userCreatedImagesAlbum.count - 1
        guard cacheImages >= 1 else { return }
                
        imageView.image = userCreatedImagesAlbum[cacheImages - 1]
        selectedImage = userCreatedImagesAlbum[cacheImages - 1]
        
        if userCreatedImagesAlbum.count > 1 {
            userCreatedImagesAlbum.removeLast()
        }
    }
    
    
    // save changes made to image
    func saveImageChanges() {
        userCreatedImagesAlbum.append(imageView.image!)
        selectedImage = imageView.image
    }
    
    
    // is used to filter default photos when app is launched and user have not choosen his photo yet
    func modifyImage(input: UIImage, filterName: String) -> UIImage {
        
        guard filterName != "Original" else { return input }
        
        selectedFilter = CIFilter(name: filterName)
        selectedFilter.setValue(CIImage(image: input), forKey: kCIInputImageKey)

        if let cgimg = context.createCGImage(selectedFilter.outputImage!, from: selectedFilter.outputImage!.extent) {
            return UIImage(cgImage: cgimg)
        } else {
            return input
        }
    }
    
    
    
    
    // MARK: - User choose photo from source (gallery/camera)
    @objc func pickUpPictureFromSource() {
        // if we change imageView.image, then the history of changes made to the image which is being changed is useless
        userCreatedImagesAlbum.removeAll()
        
        let ac = UIAlertController(title: nil, message: "Take a photo from:", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Gallery", style: .default, handler: importPictureFromGallery))
        ac.addAction(UIAlertAction(title: "Camera", style: .default, handler: takePhoto))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // camera
    func takePhoto(action: UIAlertAction) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // gallery
    func importPictureFromGallery(action: UIAlertAction) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // import photo to our app purposes
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        selectedImage = image
        
        imageView.alpha = 0.0
        self.imageView.image = image
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [], animations: {
            self.imageView.alpha = 1.0
        })
        
        saveImageChanges()
    }
    


    
    // if no photo is selected then this fun shows an alert that it is obligation to choose photo before using buttons
    func showAlertNoPhotoSelected() {
        let ac = UIAlertController(title: nil, message: "Please add photo first." , preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Okey", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    
    
    // MARK: - The usage of filters
    
    // when effect button is pressed
    @IBAction func effectsPressed(_ sender: UIButton) {
        
        guard selectedImage != nil else { showAlertNoPhotoSelected(); return }
        hideLabelAndSliders(hide: true)
        
        firstLabel.isHidden = false
        firstSlider.isHidden = false
        
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: Array(effectDict)[0].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[1].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[2].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[3].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[4].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[5].key, style: .default, handler: setEffect))
        ac.addAction(UIAlertAction(title: Array(effectDict)[6].key, style: .default, handler: setEffect))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    
    // when RGB button is pressed
    @IBAction func RGBPressed(_ sender: UIButton) {
        
        guard selectedImage != nil else { showAlertNoPhotoSelected(); return }

        hideLabelAndSliders(hide: false)
        saveImageChanges()
        
        selectedFilter = CIFilter(name: "CIColorClamp")
        setFilterName = "CIColorClamp"
        
        let beginImage = CIImage(image: selectedImage)
        selectedFilter.setValue(beginImage, forKey: kCIInputImageKey)

        applyProcessing()
    }
    
    
    // every time the value of each slider is changed
    @IBAction func intensityChanged(_ sender: Any) {
        applyProcessing()
    }
    
    
    // if effect button is pressed and the effect is choosen then this func is launched
    // it makes sure that image and filter is selected and launches next func which applies choosen adjustable filter
    func setEffect(action: UIAlertAction) {
        
        guard selectedImage != nil else { return }
        saveImageChanges()
                
        let effectName = effectDict[action.title!]
        selectedFilter = CIFilter(name: effectName!)
        setFilterName = effectName!
        
        let beginImage = CIImage(image: selectedImage)
        selectedFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        // uncomment if you want to get more info about user choose filter
//        print(currentFilter.inputKeys)
//        print("\n DESCRIBTION OF FILTER's PARAMETERS: \n \n", currentFilter.attributes.description)
        
        applyProcessing()
    }
    
    
    
    func applyProcessing() {
        
        // "if condition" is used because i could have found keys for "CIColorClamp" filter
        if setFilterName == "CIColorClamp" {
            
            for i in [firstSlider, secondSlider, thirdSlider] { i?.isHidden = false}
            
            selectedFilter.setDefaults()
            selectedFilter.setValue(CIVector(x: CGFloat(firstSlider.value), y: CGFloat(secondSlider.value), z: CGFloat(thirdSlider.value), w: 0), forKey: "inputMinComponents")
            selectedFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")
            
        } else {
            
            firstSlider.isHidden = false
            for i in [secondSlider, thirdSlider] { i?.isHidden = true}

            let inputKeys = selectedFilter.inputKeys
            if inputKeys.contains(kCIInputIntensityKey) { selectedFilter.setValue(firstSlider.value, forKey: kCIInputIntensityKey) }
            if inputKeys.contains(kCIInputRadiusKey) { selectedFilter.setValue(firstSlider.value * 200, forKey: kCIInputRadiusKey) }
            if inputKeys.contains(kCIInputScaleKey) { selectedFilter.setValue(firstSlider.value * 10, forKey: kCIInputScaleKey) }
            if inputKeys.contains(kCIInputCenterKey) { selectedFilter.setValue(CIVector(x: selectedImage.size.width / 2, y: selectedImage.size.height / 2), forKey: kCIInputCenterKey) }
        }
            

        if let cgimg = context.createCGImage(selectedFilter.outputImage!, from: selectedFilter.outputImage!.extent) {
            print()
            let processedImage = UIImage(cgImage: cgimg)
            self.imageView.image = processedImage
        }
    }
    
    
    
    // MARK: - Saves modified photo to user library
    
    @objc func saveToGallery() {
        
        guard selectedImage != nil else { return }
        
        // returns alert if user have not made any changes to uploaded photo and wants to save it
        guard let image = imageView.image else {
            let ac = UIAlertController(title: "Not saved", message: "You have not made any changes so there is nothing to be saved.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .cancel))
            present(ac, animated: true)
            return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // while saving - this func will show the error if it occurs
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        if let error = error {
            //error occured
            let ac = UIAlertController(title: "error", message: "There was a problem while saving image, please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .default))
            present(ac, animated: true)
            print(error.localizedDescription)
        } else {
            return
        }
    }
    
}




// MARK: - CollectionView (horizontal scroll)

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 100 }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "tableviewcellid", for: indexPath) as? TableViewCell {

            var rowArray: [CVCM2]
            
            if userImageObjectsArr != nil {
                rowArray = userImageObjectsArr[indexPath.section].photos[indexPath.row]
            } else {
                rowArray = colorsArray.objectsArray[indexPath.section].photos[indexPath.row]
            }
                
            cell.updateCellWith(row: rowArray)
            
            cell.cellDelegate = self

            cell.selectionStyle = .none
            return cell
       }
        return UITableViewCell()
    }
    
    
    // cannot be deleted because of protocol (this func is not used)
    func collectionView(collectionviewcell: CollectionViewCell?, index: Int, didTappedInTableViewCell: TableViewCell) {

        if let colorsRow = didTappedInTableViewCell.rowWithFilters {
            tappedCell = colorsRow[index]
            // You can also do changes to the cell you tapped using the 'collectionviewcell'
        }
    }
}



// MARK: - Notification center
// needed to get number of touched collection from TableViewCell (in other ways there was a problem with "imageView" IBOutlet which was nill > error)
extension Notification.Name {
    static let sentFilterNumberNotification = Notification.Name(rawValue: "rawValue")
}

