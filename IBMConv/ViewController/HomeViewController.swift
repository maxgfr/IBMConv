//
//  ViewController.swift
//  IBMConv
//
//  Created by GOLFIER on 21/12/2017.
//  Copyright © 2017 GOLFIER. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ConversationV1

class HomeViewController: JSQMessagesViewController {
    
    //defaults param
    let defaults = UserDefaults.standard
    
    //Users
    var currentUser: User!
    var watsonUser: User!
    
    // All messages of user1, user2
    var messages = [JSQMessage]()
    
    //Conversation
    let usernameConv = Credentials.ConversationUsername
    let passwordConv = Credentials.ConversationPassword
    let versionConv = Credentials.ConversationVersion
    let workspaceIDConv = Credentials.ConversationWorkspace
    var conversation: Conversation!
    var context: Context? // save context to continue conversation
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let username = defaults.string(forKey: "Identifiant")
        //If the user is connected
        if (username != nil) {
            currentUser = User(id: "1", name: username!)
        } else {
            currentUser = User(id: "1", name: "Not identified")
        }
        //Initialize Watson user
        watsonUser = User(id: "2", name: "Watson")
        
        // Tell to JSQMessagesViewController who is the current user
        self.senderId = currentUser.id
        self.senderDisplayName = currentUser.name
        
        //Initialize a conversation
        conversation = Conversation(username: usernameConv, password: passwordConv, version: versionConv)
        
        //Receive the first message
        let failure = { (error: Error) in print(error) }
        conversation.message(workspaceID: workspaceIDConv, failure: failure) {
            response in
            //print(response.output.text)
            for word in response.output.text {
                //let msg = JSQMessage(senderId: "2", displayName: "Watson", text: word)
                //self.messages.append(msg!)
                print(word)
            }
            self.context = response.context
        }
        self.messages.append(JSQMessage(senderId: "2", displayName: "Watson", text: "Bonjour, comment puis-je vous aider ?"))
    }
    
    override func viewDidAppear(_ animated: Bool){
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "Identifiant")
        if (username == nil) {
            self.performSegue(withIdentifier: "loginView", sender: self);
        } else {
            //Change the current name
            currentUser.name = username!
            self.senderDisplayName = currentUser.name
            print(username!)
        }
    }
    
    @IBAction func onClickDeco(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "Identifiant")
        print("Deconnexion")
        self.performSegue(withIdentifier: "loginView", sender: self);
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        self.messages.append(message!)
        
        //Synchronisation
        let myGroup = DispatchGroup()
        //Let's wait
        myGroup.enter()
        // Send text to conversation service
        let input = InputData(text: text)
        let request = MessageRequest(input: input, context: context)
        let failure = { (error: Error) in print(error) }
        conversation.message( workspaceID: workspaceIDConv, request: request, failure: failure) {
            response in
            print(response.output.text)
            for word in response.output.text {
                let msg = JSQMessage(senderId: "2", displayName: "Watson", text: word)
                self.messages.append(msg!)
            }
            myGroup.leave()
        }
        
        // We received the message
        myGroup.notify(queue: .main) {
            print("message received")
            self.finishSendingMessage()
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        let messageUsername = message.senderDisplayName
        return NSAttributedString(string: messageUsername!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        //Disable attachment button
        self.inputToolbar.contentView.leftBarButtonItem = nil
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let message = messages[indexPath.row]
        
        if currentUser.id == message.senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: .green)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .blue)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
}
