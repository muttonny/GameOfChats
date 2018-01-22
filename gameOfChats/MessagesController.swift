//
//  ViewController.swift
//  gameOfChats
//
//  Created by Tony Mut on 12/18/17.
//  Copyright © 2017 zimba. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {
    
    var messages = [Message]()
    var messageDictionary = [String : Message]()
    
    let cellId = "cellId"
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
               
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "compose")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
                
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.allowsSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print(indexPath.row)
        
        guard let uid = Auth.auth().currentUser?.uid else {
        
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
        
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                
                    print("Failed to delete message ", error)
                    return
                }
                
                self.messageDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
            })
        }
        
        
    }
    
    func observeUserMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid else{
        
            return
        }
    
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                
                self.fetchMessageWithMessageId(messageId: messageId)
                
                }, withCancel: nil)
            
            }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            
            self.messageDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
            }, withCancel: nil)
    }
    
    func handleReloadTable(){
    
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func fetchMessageWithMessageId(messageId: String){
    
        let messageReference = Database.database().reference().child("messages").child(messageId)
        
        messageReference.observe(.value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String : AnyObject] {
                
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
                
                if let chatPartnerId = message.chatPartnerId() {
                    
                    self.messageDictionary[chatPartnerId] = message
                    
                }
                
                self.attemptReloadOfTable()
                
            }
            
            }, withCancel: nil)
    }
    
    private func attemptReloadOfTable(){
        
        self.messages = Array(self.messageDictionary.values)
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    func handleNewMessage(){
    
        let newMessageController = NewMessageViewController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
    
        if Auth.auth().currentUser?.uid == nil {
            
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else{
            
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle(){
    
        guard let uid = Auth.auth().currentUser?.uid else {
        
            return
        }
        
        Database.database().reference().child("users").child(uid).observe(.value, with: { (snapshot) in
            
            print(snapshot)
            
            if let dictionary = snapshot.value as? [String : AnyObject] {
                
//                self.navigationItem.title = dictionary["name"] as? String
                
                let user = User()
                user.setValuesForKeys(dictionary)
                
                self.setupNavBarWithUser(user: user)
            }
            
            }, withCancel: nil)
        
    }
    
    func setupNavBarWithUser(user: User) {
        
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.red
        
        let containerview = UIView()
        containerview.translatesAutoresizingMaskIntoConstraints = false
        
        let profileImageview = UIImageView()
        profileImageview.translatesAutoresizingMaskIntoConstraints = false
        profileImageview.contentMode = .scaleAspectFill
        profileImageview.layer.cornerRadius = 20
        profileImageview.clipsToBounds = true
        
        if let profileImageUrl = user.profileImageUrl {
        
            profileImageview.loadImageUsingCacheWithUrlString(urlStirng: profileImageUrl)
        }else{
            profileImageview.image = UIImage(named: "profile")
        }
        
        let nameLabel = UILabel()
        
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //add nameLabel and profileImageview to the containerview and containerview to titleview
        containerview.addSubview(profileImageview)
        containerview.addSubview(nameLabel)
        titleView.addSubview(containerview)
        
        
        //constraints profileImageview
        profileImageview.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
        profileImageview.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        profileImageview.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageview.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.navigationItem.titleView = titleView
        
        //constraints nameLabel
        nameLabel.leftAnchor.constraint(equalTo: profileImageview.rightAnchor, constant: 10).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageview.heightAnchor).isActive = true
        
        //constraints containerview
        containerview.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerview.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        //add a gesture recognizer to titleview
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
    }
    
    func showChatControllerForUser(user: User){
        
        let chatController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        
        chatController.user = user
        navigationController?.pushViewController(chatController, animated: true)
    }

    func handleLogout(){
        
        do {
        
            try Auth.auth().signOut()
            
        } catch let logoutError {
        
            print("LogoutError: \(logoutError)")
        }
    
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
        
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observe(.value, with: { (snapshot) in
            print(snapshot)
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
            
                return
            }
            
            let user = User()
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary)
            
            self.showChatControllerForUser(user: user)
            
            }, withCancel: nil)
        
    }

}

