/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

//UICollectionView Tutorial: Reusable Views, Selection and Reordering
//Adding Section Headers
//Connecting the Section Header to Data
//Interacting With Cells
//Selecting a Single Cell
//Providing Selection Feedback
//Loading the Large Image
//Multiple Selection
//Keeping Track of Sharing
//Adding a Share Button
//Reordering Cells
//Implementing Drag Interactions
//Implementing Drop Interactions
//Making the Drop
//Where to Go From Here?

import UIKit

class FlickrPhotosViewController: UICollectionViewController {
  
//  The process for selecting cells in UICollectionView is very similar to that of UITableView.
//  Be sure to let UICollectionView know to allow multiple selection by setting a property.
//  The sharing flow follows these steps:
//  1. The user taps the Share bar button to invoke the multiple selection mode.
//  2. The user then taps as many photos as desired, adding each to an array.
//  3. The user taps the share button again, bringing up the native share sheet.
//  4. When the share action completes or cancels, the cells deselect and the collection view returns to single selection mode.
  private var selectedPhotos: [FlickrPhoto] = [] // keeps track of currently selected photos while in sharing mode
  private let shareLabel = UILabel() // gives the user feedback about how many photos are currently selected.
  
  private let reuseIdentifier = "FlickrCell"
  private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  
  //  searches is an array that will keep track of all the searches made in the app, and flickr is a reference to the object that will do the searching for you.
  private var searches: [FlickrSearchResults] = []
  private let flickr = Flickr()
  private let itemsPerRow: CGFloat = 3
  
  //  This keeps track of the currently selected cell:
  // 1.
  var largePhotoIndexPath: IndexPath? {
    didSet {
      // 2.
      var indexPaths: [IndexPath] = []
      if let largePhotoIndexPath = largePhotoIndexPath {
        indexPaths.append(largePhotoIndexPath)
      }
      
      if let oldValue = oldValue {
        indexPaths.append(oldValue)
      }
      // 3.
      collectionView.performBatchUpdates({ self.collectionView.reloadItems(at: indexPaths) }) { _ in
        // 4.
        if let largePhotoIndexPath = self.largePhotoIndexPath {
          self.collectionView.scrollToItem(at: largePhotoIndexPath, at: .centeredVertically, animated: true)
        }
      }
    }
    
    //    1. largePhotoIndexPath is an Optional that holds the currently selected photo item.
    //    2. When this property changes, you must also update the collection view. didSet is an easy way to manage this. You may have two cells that need to be reloaded if the user had previously selected a different cell or tapped the same cell a second time to deselect it.
    //    3. performBatchUpdates(_:completion:) will animate changes to the collection view.
    //    4. Once the animation completes, scroll the selected cell to the middle of the screen.
  }
  
  // This keeps track of sharing
  var sharing: Bool = false {
    didSet {
      // 1.
      collectionView.allowsMultipleSelection = sharing
      // 2.
      collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
      selectedPhotos.removeAll()
      
      guard let shareButton = self.navigationItem.rightBarButtonItems?.first else { return }
      
      // 3.
      guard sharing else {
        navigationItem.setRightBarButton(shareButton, animated: true)
        return
      }
      
      // 4.
      if largePhotoIndexPath != nil {
        largePhotoIndexPath = nil
      }
      
      // 5.
      updateSharedPhotoCountLabel()
      
      // 6.
      let sharingItem = UIBarButtonItem(customView: shareLabel)
      let items: [UIBarButtonItem] = [shareButton,sharingItem]
      
      navigationItem.setRightBarButtonItems(items, animated: true)
    }
    
//    sharing is a Bool with a property observer similar to largePhotoIndexPath.
//    It’s responsible for tracking and updating when this view controller enters and leaves sharing mode.
//    After the property is set, here is how the property observer responds:
//    1. Set the allowsMultipleSelection property of the collection view to the value of the sharing property.
//    2. Deselect all cells, scroll to the top and remove any existing share items from the array.
//    3. If sharing is not enabled, set the share bar button to the default state and return.
//    4. Make sure largePhotoIndexPath is set to nil.
//    5. Call the convenience method you created above to update the share label.
//    6. Update the bar button items accordingly.
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.dragInteractionEnabled = true
    collectionView.dragDelegate = self
    collectionView.dropDelegate = self
  }
  
  
  @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
    guard !searches.isEmpty else {
      return
    }
    
    guard !selectedPhotos.isEmpty else {
      sharing.toggle()
      return
    }
    
    guard sharing else {
       return
    }
    
    let images: [UIImage] = selectedPhotos.compactMap { photo in
      if let thumbnail = photo.thumbnail {
        return thumbnail
      }

      return nil
    }

    guard !images.isEmpty else {
      return
    }

    let shareController = UIActivityViewController(
      activityItems: images,
      applicationActivities: nil)
    shareController.completionWithItemsHandler = { _, _, _, _ in
      self.sharing = false
      self.selectedPhotos.removeAll()
      self.updateSharedPhotoCountLabel()
    }

    shareController.popoverPresentationController?.barButtonItem = sender
    shareController.popoverPresentationController?.permittedArrowDirections = .any
    present(shareController, animated: true, completion: nil)

//    This method will find all FlickrPhoto objects in the selectedPhotos array, ensure their thumbnail images are not nil and pass them off to a UIActivityController for presentation. iOS handles the job of presenting any system apps or services that can handle a list of images.
//    Once again, check your work!
//    Build and run, perform a search, and tap the share button in the navigation bar. Select multiple images, and watch the label update in real time as you select new cells:
//    Tap the share button again and the native share sheet will appear. If you’re on a device, you can select any app or service that accepts images to share:
  }
}



// MARK: - Private

//photo(for:) is a convenience method that will get a specific photo related to an index path in your collection view. You’re going to access a photo for a specific index path a lot, and you don’t want to repeat code.
private extension FlickrPhotosViewController {
  func photo(for indexPath: IndexPath) -> FlickrPhoto {
    return searches[indexPath.section].searchResults[indexPath.row]
  }
  
  func removePhoto(at indexPath: IndexPath) {
    searches[indexPath.section].searchResults.remove(at: indexPath.row)
  }
    
  func insertPhoto(_ flickrPhoto: FlickrPhoto, at indexPath: IndexPath) {
    searches[indexPath.section].searchResults.insert(flickrPhoto, at: indexPath.row)
  }

  
  func performLargeImageFetch(for indexPath: IndexPath, flickrPhoto: FlickrPhoto) {
    // 1.
    guard let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell else { return }
    // 2.
    cell.activityIndicator.startAnimating()
    // 3.
    flickrPhoto.loadLargeImage { [weak self] result in
      // 4.
      guard let self = self else { return }
      // 5.
      switch result {
      // 6.
      case .results(let photo):
        if indexPath == self.largePhotoIndexPath {
          cell.imageView.image = photo.largeImage
        }
      case .error(_):
        return
        
      //    1. Make sure you’ve properly dequeued a cell of the right type.
      //    2. Start the activity indicator to show network activity.
      //    3. Use the convenience method on FlickrPhoto to start an image download.
      //    4. Since you’re in a closure that captures self, ensure the view controller is still a valid object.
      //    5. Switch on the result type. If successful, & if the indexPath the fetch was performed w/ matches the current largePhotoIndexPath, then set
      //    6. the imageView on the cell to the photo’s largeImage.
      }
    }
  }
  
//  You’ll call this method to keep the shareLabel text up to date. This method checks the sharing property.
//  If the app is currently sharing photos, it will properly set the label text and
//  animate the size change to fit along with all the other elements in the navigation bar.
  func updateSharedPhotoCountLabel() {
    if sharing {
      shareLabel.text = "\(selectedPhotos.count) photos selected"
    } else {
      shareLabel.text = ""
    }
    
    shareLabel.textColor = themeColor
    
    UIView.animate(withDuration: 0.3) {
      self.shareLabel.sizeToFit()
    }
  }
}

extension FlickrPhotosViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // 1.
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    textField.addSubview(activityIndicator)
    activityIndicator.frame = textField.bounds
    activityIndicator.startAnimating()
    
    flickr.searchFlickr(for: textField.text!) { searchResults in
      activityIndicator.removeFromSuperview()
      
      switch searchResults {
      case .error(let error):
        // 2.
        print("Error Searching: \(error)")
      case .results(let results):
        // 3.
        print("Found \(results.searchResults.count) matching \(results.searchTerm)")
        self.searches.insert(results, at: 0)
        // 4.
        self.collectionView?.reloadData()
      }
    }
    
    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
  
  //  1. After adding an activity view, use the Flickr wrapper class to search Flickr asynchronously for photos that match the given search term. When the search completes, the completion block is called with the result set of FlickrPhoto objects and an error (if there was one).
  //  ***2. Log any errors to the console. Obviously, in a production application you would want to display these errors to the user.***
  //  3. Log the results and add them at the beginning of the searches array.
  //  4.Refresh the UI to show the new data. You use reloadData(), which works just like it does in a table view.
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotosViewController {
  //1
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  //2
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  //3
  //  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
  //    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? FlickrPhotoCell else { return UICollectionViewCell() }
  //    let flickrPhoto = photo(for: indexPath)
  //    cell.backgroundColor = .white
  //    cell.imageView.image = flickrPhoto.thumbnail
  //
  //    return cell
  
  //    The cell coming back is now a FlickrPhotoCell.
  //    You need to get the FlickrPhoto representing the photo to display by using the convenience method from earlier.
  //    You populate the image view with the thumbnail.
  
  // *** replacing method from first version, commenting out to leave old comments ***
  
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier, for: indexPath) as? FlickrPhotoCell else { preconditionFailure("Invalid cell type") }
    
    let flickrPhoto = photo(for: indexPath)
    
    // 1
    cell.activityIndicator.stopAnimating()
    
    // 2
    guard indexPath == largePhotoIndexPath else {
      cell.imageView.image = flickrPhoto.thumbnail
      return cell
    }
    
    // 3
    guard flickrPhoto.largeImage == nil else {
      cell.imageView.image = flickrPhoto.largeImage
      return cell
    }
    
    // 4
    cell.imageView.image = flickrPhoto.thumbnail
    
    // 5
    performLargeImageFetch(for: indexPath, flickrPhoto: flickrPhoto)
    
    return cell
    
//    Here is an explanation of the work being done above:
//    1. Stop the activity indicator in case it was currently active.
//    2. If the largePhotoIndexPath does not match the indexPath of the current cell, set the image to thumbnail and return.
//    3. If the largePhotoIndexPath isn’t nil, set the image to the large image and return.
//    4. At this point, this is a cell in need of a large image display. Set the thumbnail first.
//    5. Call the private convenience method you created above to fetch the large image version and return the cell.
//    Now is a great time to build and run to check your work. Perform a search, then select an image cell. You’ll see it scales up and animates to the center of the screen. Tapping it again animates it back to its original state.
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    // 1
    switch kind {
    // 2
    case UICollectionView.elementKindSectionHeader:
      // 3
      guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(FlickrPhotoHeaderView.self)", for: indexPath) as? FlickrPhotoHeaderView
      else {
        fatalError("Invalid view type")
      }
      
      let searchTerm = searches[indexPath.section].searchTerm
      headerView.label.text = searchTerm
      return headerView
    default:
      // 4
      assert(false, "Invalid element type")
    }
    //    This method is similar to collectionView(_:cellForItemAt:), but it returns a UICollectionReusableView instead of a UICollectionViewCell.
    //    Here is the breakdown of this method:
    //    Use the kind supplied to the delegate method, ensuring you receive the correct element type.
    //    The UICollectionViewFlowLayout supplies UICollectionView.elementKindSectionHeader for you. By checking the header box in an earlier step, you told the flow layout to begin supplying headers. If you weren’t using the flow layout, you wouldn’t get this behavior for free.
    //    Dequeue the header using the storyboard identifier and set the text on the title label.
    //    Place an assert here to ensure this is the right response type.
  }
}

// MARK: - Collection View Flow Layout Delegate
extension FlickrPhotosViewController : UICollectionViewDelegateFlowLayout {
  //1
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    //    This logic calculates the size of the cell to fill as much of the collection view as possible while maintaining the cell’s aspect ratio. Since you’re increasing the size of the cell, you need a larger image to make it look good. This requires downloading the larger image upon request.
    if indexPath == largePhotoIndexPath {
      let flickrPhoto = photo(for: indexPath)
      var size = collectionView.bounds.size
      size.height -= (sectionInsets.top + sectionInsets.bottom)
      size.width -= (sectionInsets.left + sectionInsets.right)
      return flickrPhoto.sizeToFillWidth(of: size)
    }
    
    //2
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  //3
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  // 4
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}

//collectionView(_:layout:sizeForItemAt:) is responsible for telling the layout the size of a given cell.
//Here, you work out the total amount of space taken up by padding. There will be n + 1 evenly sized spaces, where n is the number of items in the row. The space size can be taken from the left section inset. Subtracting this from the view’s width and dividing by the number of items in a row gives you the width for each item. You then return the size as a square.
//collectionView(_:layout:insetForSectionAt:) returns the spacing between the cells, headers, and footers. A constant is used to store the value.
//This method controls the spacing between each line in the layout. You want this to match the padding at the left and right.

// MARK: - UICollectionViewDelegate
extension FlickrPhotosViewController {
  override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    guard !sharing else { // This will allow selection while the user is in sharing mode.
      return true
    }
    
    if largePhotoIndexPath == indexPath {
      largePhotoIndexPath = nil
    } else {
      largePhotoIndexPath = indexPath
    }
    //  This method is pretty simple. If the IndexPath of the cell the user tapped is already selected, set largePhotoIndexPath to nil. Otherwise, set it to the current value of indexPath.
    //  This will fire the didSet property observer you just implemented.
    return false
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard sharing else { return }
    let flickrPhoto = photo(for: indexPath)
    if let index = selectedPhotos.firstIndex(of: flickrPhoto) {
      selectedPhotos.remove(at: index)
      updateSharedPhotoCountLabel()
      
      // This method removes an item from the selectedPhotos array and updates the label if a selected cell is tapped to deselect it.
    }
  }
}

// MARK: - UICollectionViewDragDelegate
extension FlickrPhotosViewController: UICollectionViewDragDelegate {
  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    let flickrPhoto = photo(for: indexPath)
    guard let thumbnail = flickrPhoto.thumbnail else {
      return []
    }
    let item = NSItemProvider(object: thumbnail)
    let dragItem = UIDragItem(itemProvider: item)
    return [dragItem]
    
//    collectionView(_:itemsForBeginning:at:) is the only required method for this protocol, and it’s also the only one you need for this feature.
//    In this method, you find the correct photo in the cached array and ensure it has a thumbnail. The must return an array of UIDragItem objects. UIDragItem is initialized with an NSItemProvider object. You can initialize an NSItemProvider with any data object you wish to provide.
    
//    Next, you need to let the collection view know that it’s able to handle drag interactions. Implement viewDidLoad() above share(_:):
//
//    In this method, you let the collection view know that drag interactions are enabled and set the drag delegate to self.
//    Now’s a great time to build and run. Perform a search, and now you’ll be able to long-press on a cell to see the drag interaction. You’ll see it lift up and you’ll be able to drag it around, but you won’t be able to drop it anywhere just yet.
  }
}

// MARK: - UICollectionViewDropDelegate
//Now you’ll need to implement some methods from UICollectionViewDropDelegate to enable the collection view to accept dropped items from a drag session. This will also allow you to reorder the cells by taking advantage of the provided index paths from the drop methods.
extension FlickrPhotosViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      canHandle session: UIDropSession) -> Bool {
    return true
//    Typically in this method, you would inspect the proposed drop items and decide if you wanted to accept them. Since you’re only enabling drag-and-drop for one item type in this app, you simply return true here.
  }
  
  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    // 1
    guard let destinationIndexPath = coordinator.destinationIndexPath else {
      return
    }
    
    // 2
    coordinator.items.forEach { dropItem in
      guard let sourceIndexPath = dropItem.sourceIndexPath else {
        return
      }

      // 3
      collectionView.performBatchUpdates({
        let image = photo(for: sourceIndexPath)
        removePhoto(at: sourceIndexPath)
        insertPhoto(image, at: destinationIndexPath)
        collectionView.deleteItems(at: [sourceIndexPath])
        collectionView.insertItems(at: [destinationIndexPath])
      }, completion: { _ in
        // 4
        coordinator.drop(dropItem.dragItem,
                          toItemAt: destinationIndexPath)
      })
    }
    
//    This delegate method accepts the drop items and performs maintenance on the collection view and the underlying data storage array to properly reorder the dropped items. You’ll see a new object here: UICollectionViewDropCoordinator. This is a UIKit object that gives you more information about the proposed drop items.
//    Here’s what happens, in detail:
//    1. Get the destinationIndexPath from the drop coordinator.
//    2. Loop through the items — an array of UICollectionViewDropItem objects — and ensure each has a sourceIndexPath.
//    3. Perform batch updates on the collection view, removing items from the array at the source index and inserting them in the destination index. After that is complete, perform deletes and updates on the collection view cells.
//    4. After completion, perform the drop action.
  }

  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
  }
  
//  The UIKit drop session calls this method constantly during interaction to interpolate where the user is dragging the items and give other objects a chance to react to the session.
//  This delegate method causes the collection view respond to the drop session with a UICollectionViewDropProposal that indicates the drop will move items and insert them at the destination index path.
}


