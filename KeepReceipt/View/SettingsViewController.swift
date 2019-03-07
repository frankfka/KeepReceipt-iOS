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
        authViewController.navigationBar.tintColor = UIColor.white
        authViewController.navigationBar.barTintColor = UIColor(named: "primary")!
        authViewController.navigationBar.prefersLargeTitles = true
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
        
        DatabaseService.syncFirebaseForFirstTime()
    }
    
    @IBAction func importButtonPressed(_ sender: Any) {
        
        DatabaseService.importFromFirebase()
    }
}
