/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import Foundation
import PromiseKit

fileprivate let appID = ""

class WeatherHelper {
  
  struct Weather {
    let tempInK: Double
    let iconName: String
    let text: String
    let name: String
    
    init?(jsonDictionary: [String: Any]) {
      
      guard let main =  jsonDictionary["main"] as? [String: Any],
        let tempInK = main["temp"] as? Double,
        let weather = (jsonDictionary["weather"] as? [[String: Any]])?.first,
        let iconName = weather["icon"] as? String,
        let text = weather["description"] as? String,
        let name = jsonDictionary["name"] as? String else {
        print("Error: invalid jsonDictionary! Verify your appID is correct")
        return nil
      }
      self.tempInK = tempInK
      self.iconName = iconName
      self.text = text      
      self.name = name
    }
  }
  
  func getWeatherTheOldFashionedWay(latitude: Double, longitude: Double, completion: @escaping (Weather?, Error?) -> ()) {
    
    assert(appID != "<#Enter Your API Key from http://openweathermap.org/appid#>", "You need to set your API key!")
    
    let urlString = "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(appID)"
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request) { data, response, error in
      
      guard let data = data,
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
        let result = Weather(jsonDictionary: json) else {
          completion(nil, error)
          return
      }
      
      completion(result, nil)
    }
    dataTask.resume()
  }
    
    
    func getWeather(latitude: Double, longitude: Double) -> Promise<Weather>{
        return Promise {fulfill, reject in
            let urlString = "http://api.openweathermap.org/data/2.5/weather?lat=" +
            "\(latitude)&lon=\(longitude)&appid=\(appID)"
            let url = URL(string: urlString)!
            let request = URLRequest(url: url)
            
            let session = URLSession.shared
            
            //PromiseKit provides a new overload of URLSession.dataTask(with:) that returns a URLDataPromise, which is just a specialized Promise. Note the data promise automatically starts its underlying data task.
            let dataPromise: URLDataPromise = session.dataTask(with: request)
            
            // The returned dataPromise has a convenience method asDictionary(), which handles deserializing the JSON for you, significantly reducing the amount of code.
            _ = dataPromise.asDictionary().then{ dictionary -> Void in
                
                // Since the dictionary is already parsed, you use it to create a result. You d this using guard let to ensure a Weather object can be created from the dictionary. If not, you create an error and call reject, similar to before. Otherwise, you call fulfill with the result.
                guard let result = Weather(jsonDictionary: dictionary as! [String : Any])
                    else{
                        let error = NSError (domain: "PromiseKitTutorial", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unkown error"])
                        reject(error)
                        return
                }
                
                fulfill(result)
                
                // Along the way, the network request could fail, or the resulting JSON deserializing could fail. Before both conditions had to be checked individually. Here, a single catch block forwards any errors on through the fail closure.
            }.catch(execute: reject)
            
        }
    }
  
  private func saveFile(named: String, data: Data, completion: @escaping (Error?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png") {
        do {
          try data.write(to: path)
          print("Saved image to: " + path.absoluteString)
          completion(nil)
        } catch {
          completion(error)
        }
      }
    }
  }
  
  private func getFile(named: String, completion: @escaping (UIImage?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      var image: UIImage?
      if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png") {
        if let data = try? Data(contentsOf: path) {
          image = UIImage(data: data)
        }
      }
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
  
}
