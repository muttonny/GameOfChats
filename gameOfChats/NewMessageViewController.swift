//
//  NewMessageViewController.swift
//  gameOfChats
//
//  Created by Tony Mut on 12/21/17.
//  Copyright © 2017 zimba. All rights reserved.
//

import UIKit
import Firebase

class NewMessageViewController: UITableViewController {
    
    let cellId = "cellId"
    var users = [User]()
    
    var messagesController : MessagesController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUsers()
    }
    
    func fetchUsers(){
    
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            
            if let dictionary = snapshot.value as? [String : AnyObject] {
            
                let user = User()
                user.id = snapshot.key
                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                print(user.name, user.email, self.users.count)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            }, withCancel: nil)
    }
    
    func handleCancel(){
    
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email?.lowercased()
        
        if let profileImageUrl = user.profileImageUrl {
            
            cell.profileImageview.loadImageUsingCacheWithUrlString(urlStirng: profileImageUrl)
        
//            let url = URL(string: profileImageUrl)
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, responce, error) in
//                
//                if error != nil {
//                
//                    print("Errorr----- \(error)")
//                    return
//                }
//                
//                DispatchQueue.main.async {
//                    cell.profileImageview.image = UIImage(data: data!)
//                }
//                
//            }).resume()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Item: \(indexPath.row) selected")
        dismiss(animated: true) {
            
            let user = self.users[indexPath.row]
            
            self.messagesController?.showChatControllerForUser(user: user)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

}
