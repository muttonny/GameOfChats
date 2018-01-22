//
//  LoginController+handlers.swift
//  gameOfChats
//
//  Created by Tony Mut on 12/22/17.
//  Copyright © 2017 zimba. All rights reserved.
//

import UIKit
import Firebase

extension LoginController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{


    func handleSelectProfileImageView(){
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        print("Info..\(info)")
        
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            
            selectedImageFromPicker = editedImage
        
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
        
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
        
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func handleRegister(){
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            if error != nil {
                
                print("Errorr: \(error)")
                return
            }
            
            //successfully authenticated
            
            guard let uid = user?.uid else {
                
                return
            }
            
            //upload image
            
            let imageName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
            
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
            
        
//            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                    
                        print("-----Error----\(error)")
                        return
                    }
                    
                    print(metadata)
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                    
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                    }
                    
                })
            }
            
            
        }
        
    }
    
    private func registerUserIntoDatabaseWithUID(uid : String, values : [String : AnyObject]){
    
        let ref = Database.database().reference()
//        (fromURL: "https://gameofchats-7e1ef.firebaseio.com/");
        let usersReference = ref.child("users").child(uid)

        usersReference.updateChildValues(values, withCompletionBlock: { (err, dbRef) in
            
            if err != nil {
                
                print("Errorr: \(err)")
                return
            }
            
            print("User saved successfully into firebase db")
            
//            self.messagesController?.fetchUserAnsSetupNavBar()
            
//            self.messagesController?.navigationItem.title = values["name"] as? String
            
            let user = User();
            
            //this setter crushes if keys donot match
            user.setValuesForKeys(values)
            
            self.messagesController?.setupNavBarWithUser(user: user)
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    

}
