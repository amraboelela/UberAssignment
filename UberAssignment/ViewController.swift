//
//  ViewController.swift
//  UberAssignment
//
//  Created by Amr on 10/11/17.
//  Copyright © 2017 Amr Aboelela. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    var photoArray: [[String: AnyObject]]?
    var photoData = [String: Data]()
    var loadingPhotos = Set<String>()
    var searchTerm = "kittens"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let size = self.view.frame.size.width / 3.0 - 2
        let cellSize = CGSize(width:size , height:size)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        loadData()
    }

    //MARK:- Data handling
    
    func loadData() {
        searchTerm = searchTerm.replacingOccurrences(of: " ", with: "-")
        guard let url = URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&format=json&nojsoncallback=1&text=\(searchTerm)") else {
            print("Failed to retrieve url")
            return
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url)
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let dictionary = object as? [String: AnyObject] {
                    if let photos = dictionary["photos"] as? [String: AnyObject] {
                        if let photo = photos["photo"] as? [[String: AnyObject]] {
                            self.photoArray = photo
                            DispatchQueue.main.async {
                                print("retrieved data successfully")
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                self.collectionView.setContentOffset(CGPoint(x:0,y:0), animated:true)
                                self.collectionView.reloadData()
                            }
                        }
                    }
                    
                }
            } catch {
                print("Failed to retrieve / parse data. url=\(url) error=\(error)")
            }
        }
    }
    
    //MARK: - Collection view
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = self.view.frame.size.width / 2.0
        return CGSize(width: size, height: size)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cellPhoto = photoArray?[indexPath.row], let id = cellPhoto["id"] as? String {
            if let imageData = photoData[id] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrCell", for: indexPath) as! FlickrCollectionViewCell
                if let image = UIImage(data: imageData as Data) {
                    cell.photoImageView.image = image
                } else {
                    print("Failed to get image from image data.")
                }
                return cell
            } else {
                if !loadingPhotos.contains(id) {
                    print("loading image with id \(id)")
                    loadingPhotos.insert(id)
                    DispatchQueue.global(qos: .background).async {
                        if let farm = cellPhoto["farm"] as? Int, let server = cellPhoto["server"] as? String, let secret = cellPhoto["secret"] as? String {
                            var imageData:Data
                            guard let url = URL(string: "http://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret).jpg") else {
                                print("Failed to retrieve url")
                                return
                            }
                            do {
                                imageData = try Data(contentsOf: url)
                                DispatchQueue.main.async {
                                    self.photoData[id] = imageData
                                    self.collectionView.reloadData()
                                }
                            } catch {
                                print("Failed to retrieve image data. url=\(url) error=\(error)")
                            }
                        }
                    }
                }
            }
        }
        //print("loading cell in indexPath: \(indexPath)")
        let loadingCell = collectionView.dequeueReusableCell(withReuseIdentifier: "loadingCell", for: indexPath)
        return loadingCell
    }
    
    //MARK: - Delegates
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTerm = searchBar.text ?? ""
        if !searchTerm.isEmpty {
            print("searching for \(searchTerm)")
            self.loadData()
        }
    }
    
}

