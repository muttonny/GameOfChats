//
//  Extensions.swift
//  gameOfChats
//
//  Created by Tony Mut on 12/28/17.
//  Copyright © 2017 zimba. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlStirng: String){
        
        //set image to view to avoid reusing a downloaded image in different cells
        self.image = nil
        
        //check if image was cached before downloading it
        if let cachedImage = imageCache.object(forKey: urlStirng as AnyObject) as? UIImage{
        
            self.image = cachedImage
            return
        }
        
        //otherwise download a new image
        let url = URL(string: urlStirng)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, responce, error) in
            
            if error != nil {
                
                print("Errorr----- \(error)")
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!){
                
                    imageCache.setObject(downloadedImage, forKey: urlStirng as AnyObject)
                    
                    self.image = downloadedImage
                }
                
            }
            
        }).resume()
    }
}
