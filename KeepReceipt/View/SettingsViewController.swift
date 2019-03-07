//
//  SettingsViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-03-03.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import FirebaseUI
import Eureka

class SettingsViewController: FormViewController, FUIAuthDelegate {
    
    // Available methods: syncforfirsttime, import, sign in, sign out
    
    // Firebase variables
    var authUI: FUIAuth?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpForm()
        
        
    }
    
    // Method to initialize the form
    private func setUpForm() {
        
        let currUser = Auth.auth().currentUser
        let currUserName = currUser?.displayName
        let isSignedIn = currUser != nil
        let userHasName = currUserName != nil
        // Enables smooth scrolling between form elements
        animateScroll = true
        
        form +++ Section("Account")
            <<< TextRow() { row in
                row.title = "Account"
                row.value = isSignedIn ? (userHasName ? currUserName! : "No Name") : "Not Signed In"
                row.cell.textField.isUserInteractionEnabled = false
            }
            <<< SwitchRow() { row in
                row.title = "Enable Sync"
                row.value = false
                // Change the tint background for the switch
                (row.baseCell as! SwitchCell).switchControl.onTintColor = UIColor(named: "accent")
                row.disabled = Condition(booleanLiteral: !isSignedIn)
            }
            <<< ButtonRow() { row in
                row.title = "Force Sync"
                row.baseCell.tintColor = UIColor(named: "primary")
                row.disabled = Condition(booleanLiteral: (!isSignedIn || false))
                row.onCellSelection({ (cell, row) in
                    // TODO does this get triggered when disabled?
                    print("force sync pressed")
                })
            }
            <<< ButtonRow() { row in
                row.title = "Import"
                row.baseCell.tintColor = UIColor(named: "primary")
                row.disabled = Condition(booleanLiteral: (!isSignedIn || true))
                row.onCellSelection({ (cell, row) in
                    // TODO does this get triggered when disabled?
                    print("import pressed")
                })
            }
            <<< ButtonRow() { row in
                row.title = isSignedIn ? "Sign Out" : "Sign In"
                row.baseCell.tintColor = UIColor(named: "primary")
                row.onCellSelection({ (cell, row) in
                    if isSignedIn {
                        self.signOutPressed()
                    } else {
                        self.signInPressed()
                    }
                })
            }
        
        
        // TODO a delete all row?
    }
    
    // Initialize & launch Google's default sign-in UI
    private func signInPressed() {
        authUI = FUIAuth.defaultAuthUI()
        if let auth = authUI {
            // Setup Firebase sign-in
            auth.delegate = self
            auth.providers = [FUIGoogleAuth()]
            
            let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
            authViewController.navigationBar.tintColor = UIColor.white
            authViewController.navigationBar.barTintColor = UIColor(named: "primary")!
            authViewController.navigationBar.prefersLargeTitles = true
            present(authViewController, animated: true, completion: nil)
        } else {
            print("Error creating auth UI object")
        }
    }

    // Deal with sign out
    private func signOutPressed() {
        do {
            try Auth.auth().signOut()
            UIService.showHUDWithNoAction(isSuccessful: true, with: "Signed Out Successfully")
            // Update state & stuff
        } catch {
            print("Error trying to sign out: \(error)")
        }
    }
    
    // Function called when user returns from sign-in
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // Update state variables here
        UIService.showHUDWithNoAction(isSuccessful: true, with: "Signed In Successfully")
    }
    
}
