//
//  AlbumCollectionViewController.swift
//  Virtual Tourist
//
//  Created by 강선미 on 21/10/2019.
//  Copyright © 2019 Sunmi Kang. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class AlbumCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var navTitle: UINavigationItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check pin data or not
      guard let pin = pin else {
            showAlert(title: "Can't load photo album", message: "Try Again!!")
            fatalError("No pin ")
        }
        
        navTitle.title = pin.locationName ?? "Album"
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpMapView()
        setupFetchedResultsController()
        downloadPhotoData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    // Setting up fetched results controller
       private func setupFetchedResultsController() {
           let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
          
           if let pin = pin {
               let predicate = NSPredicate(format: "pin == %@", pin)
               fetchRequest.predicate = predicate
            
               print("\(pin.latitude) \(pin.longitude)")
           }
           let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
           fetchRequest.sortDescriptors = [sortDescriptor]
           
           fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                 managedObjectContext: dataController.viewContext,
                                                                 sectionNameKeyPath: nil, cacheName: "photo")
           fetchedResultsController.delegate = self

           do {
               try fetchedResultsController.performFetch()
           } catch {
               fatalError("The fetch could not be performed: \(error.localizedDescription)")
           }
       }
    func showAlert(title: String, message: String){
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    // remove all existing images from current place
    @IBAction func newCollection(_ sender: Any) {
        guard let imageObject = fetchedResultsController.fetchedObjects else { return }
        for image in imageObject {
            dataController.viewContext.delete(image)
    
        }
        downloadPhotoData()
    }
    
    func downloadPhotoData() {

        // manage activity indicator : start running
        guard (fetchedResultsController.fetchedObjects?.isEmpty)! else {
            // show alarm
            print("image metadata is already present. no need to re download")
            return
        }

        let pagesCount = Int(self.pin.pages)
        let annotation = AnnotationPin(pin: pin)
        FlickrClient.getPhotos(latitude: annotation.pin.latitude,longitude: annotation.pin.longitude,
                               totalPageAmount: pagesCount) { (photos, totalPages, error) in

        guard photos.count > 0 else {
            print("Error!")
            return
        }

        if pagesCount == 0 {
            self.pin.pages = Int32(totalPages)
        }
        // run for loop
        for photo in photos {
            let newPhoto = Photo(context: self.dataController.viewContext)
            newPhoto.imageUrl = URL(string: photo.url_m)
            newPhoto.imageData = nil
            newPhoto.pin = self.pin
            newPhoto.imageID = UUID().uuidString

            do {
                try self.dataController.viewContext.save()
            } catch {
                print("Can't save photoes!!")
            }

        }

        // manage activity indicator : stop
      }

    }

    
    
    @IBAction func OnPressedDelete(_ sender: Any) {
       removeSelectedImages()
       dismiss(animated: true, completion: nil)
    }
    

    @IBAction func OnPressedDone(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    private func removeSelectedImages() {
      var imageIds: [String] = []
           
           // All the index paths for the selected images are returned
           if let selectedImagesIndexPaths = collectionView.indexPathsForSelectedItems {
               for indexPath in selectedImagesIndexPaths {
                   let selectedImageToRemove = fetchedResultsController.object(at: indexPath)
                   
                if let imageId = selectedImageToRemove.imageID {
                       imageIds.append(imageId)
                   }
               }
               
               for imageId in imageIds {
                   if let selectedImages = fetchedResultsController.fetchedObjects {
                       for image in selectedImages {
                           if image.imageID == imageId {
                               dataController.viewContext.delete(image)
                           }
                           do {
                               try dataController.viewContext.save()
                           } catch {
                               print("Unable to remove the photo")
                           }
                       }
                   }
               }
           }
        
    }
}


