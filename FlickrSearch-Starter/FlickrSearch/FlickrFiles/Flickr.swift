/// Copyright (c) 2018 Razeware LLC
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
	
import UIKit

//To use the Flickr API, you need an API key. If you’re doing a real project, I recommend you sign up for one here: http://www.flickr.com/services/api/keys/apply/.
//However, for test projects like this, Flickr has a sample key that they rotate out every so often. You can use the key without signing up. Simply perform any search at: http://www.flickr.com/services/api/explore/?method=flickr.photos.search and copy the API key out of the URL at the bottom – it follows the “&api_key=”” all the way to the next “&”. Paste it somewhere in a text editor for later use.

let apiKey = "9ba4c232a11a8a273bd95ac4dbb45ab5"

class Flickr {
  enum Error: Swift.Error {
    case unknownAPIResponse
    case generic
  }
  
  func searchFlickr(for searchTerm: String, completion: @escaping (Result<FlickrSearchResults>) -> Void) {
    guard let searchURL = flickrSearchURL(for: searchTerm) else {
      completion(Result.error(Error.unknownAPIResponse))
      return
    }
    
    let searchRequest = URLRequest(url: searchURL)
    
    URLSession.shared.dataTask(with: searchRequest) { (data, response, error) in
      if let error = error {
        DispatchQueue.main.async {
          completion(Result.error(error))
        }
        return
      }
      
      guard
        let _ = response as? HTTPURLResponse,
        let data = data
        else {
          DispatchQueue.main.async {
            completion(Result.error(Error.unknownAPIResponse))
          }
          return
      }
      
      do {
        guard
          let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
          let stat = resultsDictionary["stat"] as? String
          else {
            DispatchQueue.main.async {
              completion(Result.error(Error.unknownAPIResponse))
            }
            return
        }
        
        switch (stat) {
        case "ok":
          print("Results processed OK")
        case "fail":
          DispatchQueue.main.async {
            completion(Result.error(Error.generic))
          }
          return
        default:
          DispatchQueue.main.async {
            completion(Result.error(Error.unknownAPIResponse))
          }
          return
        }
        
        guard
          let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
          let photosReceived = photosContainer["photo"] as? [[String: AnyObject]]
          else {
            DispatchQueue.main.async {
              completion(Result.error(Error.unknownAPIResponse))
            }
            return
        }
        
        let flickrPhotos: [FlickrPhoto] = photosReceived.compactMap { photoObject in
          guard
            let photoID = photoObject["id"] as? String,
            let farm = photoObject["farm"] as? Int ,
            let server = photoObject["server"] as? String ,
            let secret = photoObject["secret"] as? String
            else {
              return nil
          }
          
          let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)
          
          guard
            let url = flickrPhoto.flickrImageURL(),
            let imageData = try? Data(contentsOf: url as URL)
            else {
              return nil
          }
          
          if let image = UIImage(data: imageData) {
            flickrPhoto.thumbnail = image
            return flickrPhoto
          } else {
            return nil
          }
        }
        
        let searchResults = FlickrSearchResults(searchTerm: searchTerm, searchResults: flickrPhotos)
        DispatchQueue.main.async {
          completion(Result.results(searchResults))
        }
      } catch {
        completion(Result.error(error))
        return
      }
    }.resume()
  }
  
  private func flickrSearchURL(for searchTerm:String) -> URL? {
    guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
      return nil
    }
    
    let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
    return URL(string:URLString)
  }
}
