//
//  SettingsViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-03-03.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import FirebaseUI

class SettingsViewController: UIViewController, FUIAuthDelegate {
    
    var authUI: FUIAuth?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authUI = FUIAuth.defaultAuthUI()
        if let auth = authUI {
            // Setup Firebase sign-in
            authUI!.delegate = self
            let providers: [FUIAuthProvider] = [FUIGoogleAuth()]
            authUI!.providers = providers
        } else {
            print("error")
        }
        
        // test current sign in
        if let user = authUI?.auth?.currentUser {
            print("UID: \(user.uid)")
        } else {
            print("no user")
        }
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    @IBAction func signOutPressed(_ sender: UIButton) {
        try! Auth.auth().signOut()
        print(Auth.auth().currentUser == nil ? "no user" : "user")
    }
    
    // Function called when user returns from sign-in
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if error == nil {
            print("UID (didsignin): \(authUI.auth!.currentUser!.uid)")
        } else {
            print(error)
        }
    }
    
    @IBAction func syncButtonPressed(_ sender: UIButton) {
        // delete anything that currently exists?
        
        // two main collections -> receipts and categories
        if let user = Auth.auth().currentUser {
            
            DatabaseService.syncFirebaseForFirstTime(for: user.uid)
            // User is signed in.
            // ...
        } else {
            // No user is signed in.
            // ...
        }
    }
    
    @IBAction func importButtonPressed(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            DatabaseService.importFromFirebase(for: user.uid)
        }
    }
}
