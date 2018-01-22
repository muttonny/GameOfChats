//
//  ChatLogController.swift
//  gameOfChats
//
//  Created by Tony Mut on 1/4/18.
//  Copyright © 2018 zimba. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let cellId = "cellId"
    
    var containerviewBottomAnchor: NSLayoutConstraint?
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    var messages = [Message]()
    
    var user: User? {
    
        didSet{
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
//        setupInputComponents()
//        
        setupKeyboardObservers();
    }
    
    lazy var inputContainerview: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView

    }()
    
    func handleUploadTap(){
    
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            
            //we selected a video
            handleVideoSelectedForUrl(url: videoUrl)
        
        }else{
        
            //we selected an image
            hanldeImageSelectedForInfo(info: info as [String : AnyObject])
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: URL){
    
        print("Video url",url)
        
        let filename = NSUUID().uuidString + ".mov"
        let uploadTask = Storage.storage().reference().child("message_movies").child(filename).putFile(from: url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                
                print("Error: ", error)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        
                        let properties = ["imageUrl" : imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl" : videoUrl] as [String: Any] as [String : AnyObject]
                        
                        self.sendMessageWithProperties(properties: properties)
                    })
                
                }
                
            }
            
            
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
            
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            
            return UIImage(cgImage: thumbnailCGImage)
        }catch let err {
        
            print("Error",err)
        }
    
        return nil
    }
    
    private func hanldeImageSelectedForInfo(info: [String : AnyObject]){
    
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            
            selectedImageFromPicker = editedImage
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()){
    
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
        
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                
                    print("Failed to upload image: ", error)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    completion(imageUrl)
                
                }
                
            })
        }
        
    }
    
    override var inputAccessoryView: UIView?{
    
        get{
            return inputContainerview
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers(){
    
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    func handleKeyboardWillShow(notification: NSNotification){
        
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
    
        print("Notification: \(keyboardFrame.height)", "Duration: \(keyboardDuration)")
        
        //move the input area above the keyboard 
        containerviewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification){
        
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
    
        //move the input area back to botttom when keyboard dismisses
        containerviewBottomAnchor?.constant = 0
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardDidShow(notification: NSNotification){
    
        if messages.count > 0 {
        
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func observeMessages(){
    
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
        
            return
        }
        
        let userMessageRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessageRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observe(.value, with: { (snapshot) in
            
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                
                    return
                }
                
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
                
                self.messages.append(message)
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    
                    //scroll to last message in the collectionview
                    let lastIndex = self.messages.count - 1
                    let lastItemIndexPath = IndexPath(item: lastIndex, section: 0)
                    self.collectionView?.scrollToItem(at: lastItemIndexPath, at: .bottom, animated: true)
                }
                
                }, withCancel: nil)
            
            }, withCancel: nil)
    }
    
//    func setupInputComponents() {
//    
//        let containerview = UIView()
//        containerview.translatesAutoresizingMaskIntoConstraints = false
//        containerview.backgroundColor = UIColor.white
//        view.addSubview(containerview)
//        
//        //constraints
//        containerview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        
//        containerviewBottomAnchor = containerview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        containerviewBottomAnchor?.isActive = true
//        
//        containerview.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        containerview.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        
//        let sendButton = UIButton(type: .system)
//        sendButton.setTitle("Send", for: .normal)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
//        containerview.addSubview(sendButton)
//        
//        //constraints send button x, y, w, h
//        sendButton.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
//        sendButton.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
//        
//        
//        containerview.addSubview(inputTextField)
//        
//        //constraints inputTextField
//        inputTextField.leftAnchor.constraint(equalTo: containerview.leftAnchor, constant: 10).isActive = true
//        inputTextField.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
//        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
//        
//        let separatorLine = UIView()
//        separatorLine.backgroundColor = UIColor(r: 220, g: 220, b: 220)
//        separatorLine.translatesAutoresizingMaskIntoConstraints = false
//        containerview.addSubview(separatorLine)
//        
//        //constraints
//        separatorLine.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
//        separatorLine.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
//        separatorLine.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
//        separatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
//    }
    
    func handleSend(){
        
        if let text = inputContainerview.inputTextField.text {
        
            let properties: [String: AnyObject] = ["text": text] as [String : Any] as [String : AnyObject]
            
            sendMessageWithProperties(properties: properties)
            
        }
        
    
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String: Any] as [String : AnyObject]
        
        sendMessageWithProperties(properties: properties)
        
    }
    
    private func sendMessageWithProperties(properties: [String : AnyObject]){
    
        let ref = Database.database().reference().child("messages")
        
        let childRef = ref.childByAutoId()
        
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                
                print("Error: \( error)")
                return
            }
            
            self.inputContainerview.inputTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let recepientUserMessagesRef  = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recepientUserMessagesRef.updateChildValues([messageId: 1])
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        cell.textview.text = message.text
        
        cell.message = message
        
        if let text = message.text {
        
            cell.bubbleWidthAnchor?.constant = estimatedFrameForText(text: text).width + 32
            
        }else if message.imageUrl != nil {
        
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        setupCell(cell: cell, message: message)
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message){
        
        if let profileImageUrl = self.user?.profileImageUrl {
        
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlStirng: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            
            //outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textview.textColor = UIColor.white
            
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        }else{
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textview.textColor = UIColor.black
            
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlStirng: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.textview.isHidden = true
            cell.bubbleView.backgroundColor = UIColor.clear
        }else{
            
            cell.messageImageView.isHidden = true
            cell.textview.isHidden = false
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        //get estimated height
        if let text = message.text {
        
            height = estimatedFrameForText(text: text).height + 20
            
        }else if message.imageUrl != nil, let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
        
            height = CGFloat(imageHeight/imageWidth * 200)
        }
         
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    func estimatedFrameForText(text: String) -> CGRect {
    
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func performZoomInForStartingImageView(startingImageView: UIImageView){
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
    
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        print("startingFrame: ",startingFrame)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
        
            keyWindow.addSubview(zoomingImageView)
            
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                self.inputContainerview.alpha = 0
                
                //calculate the height
                // h2/w2 = h1/w1
                //h2 = h1/w1 * w2
                
                let height = zoomingImageView.frame.height / zoomingImageView.frame.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
                }, completion: nil)
            
        }
        
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer){
        
        if let zoomOutImageView = tapGesture.view as? UIImageView {
            
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerview.alpha = 1
                self.startingImageView?.isHidden = false
                
                }, completion: { (completed) in
                    zoomOutImageView.removeFromSuperview()
            })
        
        }
    }
    
}
