//
//  UserCell.swift
//  gameOfChats
//
//  Created by Tony Mut on 1/6/18.
//  Copyright © 2018 zimba. All rights reserved.
//

import UIKit
import Firebase

//User cell

class UserCell: UITableViewCell {
    
    var message : Message? {
    
        didSet{
        
            setupNameAndProfileImage()
            
            if let text = message?.text {
                self.detailTextLabel?.text = text
            }else{
                self.detailTextLabel?.text = "Sent an image"
            }
            
            
            if let seconds = message?.timestamp?.doubleValue {
                
                let timestampDate = NSDate(timeIntervalSince1970: seconds)
                
                let datetFormatter = DateFormatter()
                datetFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = datetFormatter.string(from: timestampDate as Date)
            }
        }
    }
    
    private func setupNameAndProfileImage(){
        
    
        if let id = message?.chatPartnerId() {
            
            let ref = Database.database().reference().child("users").child(id)
            ref.observe(.value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String : AnyObject] {
                    
                    self.textLabel?.text = dictionary["name"] as? String
                    
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String{
                        
                        self.profileImageview.loadImageUsingCacheWithUrlString(urlStirng: profileImageUrl)
                    }
                }
                
                }, withCancel: nil)
            
        }
    }
    
    let profileImageview: UIImageView = {
        
        let imageview = UIImageView()
        imageview.translatesAutoresizingMaskIntoConstraints = false
        imageview.image = UIImage(named: "profile")
        imageview.contentMode = .scaleAspectFill
        imageview.layer.cornerRadius = 24    // 20 is half of the height and width
        imageview.layer.masksToBounds = true
        return imageview
    }()
    
    let timeLabel : UILabel = {
    
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
//        label.text = "HH:MM:SS"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
        
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageview)
        addSubview(timeLabel)
        
        //add constraints for the profileImageview
        profileImageview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageview.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageview.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageview.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        //constraints for timeLabel x, y, width, height
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 8).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

