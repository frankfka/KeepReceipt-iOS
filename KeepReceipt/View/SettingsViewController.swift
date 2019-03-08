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
    
    // Firebase variables
    var authUI: FUIAuth?
    
    // Specified settings
    let userDefaults = UserDefaults.standard
    var syncEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get saved settings
        syncEnabled = userDefaults.bool(forKey: Settings.SYNC_ENABLED)
        
        // Initialize the form
        setUpForm()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViews()
    }
    
    // Function called when user returns from sign-in
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        // Update state variables here
        UIService.showHUDWithNoAction(isSuccessful: true, with: "Signed In Successfully")
        // Update views to match
        updateViews()
    }
    
    // MARK: Private UI Helper functions
    private func updateViews() {
        
        // Get the current state
        let currUser = Auth.auth().currentUser
        let currUserName = currUser?.displayName
        let isSignedIn = currUser != nil
        let userHasName = currUserName != nil
        
        // Set the account name
        form.rowBy(tag: Constants.SIGNED_IN_AS_TAG)?.value = isSignedIn ? (userHasName ? currUserName! : Constants.SIGNED_IN_AS_NO_NAME) : Constants.SIGNED_IN_AS_NO_AUTH
        // Set the state of the sync enabled switch
        let syncEnabledSwitch = form.rowBy(tag: Constants.ENABLE_SYNC_TAG) as! SwitchRow
        syncEnabledSwitch.value = syncEnabled && isSignedIn
        syncEnabledSwitch.disabled = Condition(booleanLiteral: !isSignedIn)
        syncEnabledSwitch.reload()
        // Set disabled state of the sync/import
        let syncButton = form.rowBy(tag: Constants.SYNC_BUTTON_TAG) as! ButtonRow
        syncButton.disabled = Condition(booleanLiteral: !isSignedIn || !syncEnabled)
        syncButton.evaluateDisabled()
        let importButton = form.rowBy(tag: Constants.IMPORT_BUTTON_TAG) as! ButtonRow
        importButton.disabled = Condition(booleanLiteral: !isSignedIn || !syncEnabled)
        importButton.evaluateDisabled()
        // Initialize sign-in/out button
        let signInOutButton = form.rowBy(tag: Constants.SIGN_IN_OUT_BUTTON_TAG) as! ButtonRow
        signInOutButton.title = isSignedIn ? Constants.SIGN_OUT_TITLE : Constants.SIGN_IN_TITLE
        signInOutButton.onCellSelection { (cell, row) in
            // Action to take depends on the current state
            if isSignedIn {
                self.signOutPressed()
            } else {
                self.signInPressed()
            }
        }
        
        // Reload the form table
        tableView.reloadData()
    }
    
    // Method to initialize the form
    private func setUpForm() {
        
        // Enables smooth scrolling between form elements
        animateScroll = true
        
        form +++ Section(Constants.ACCOUNT_SETTINGS_SECTION_TITLE)
            <<< TextRow() { row in
                row.tag = Constants.SIGNED_IN_AS_TAG
                row.title = Constants.SIGNED_IN_AS_TITLE
                // Default value in row
                row.value = Constants.SIGNED_IN_AS_NO_NAME
                row.cell.textField.isUserInteractionEnabled = false
            }
            <<< SwitchRow() { row in
                row.tag = Constants.ENABLE_SYNC_TAG
                row.title = Constants.ENABLE_SYNC_TITLE
                // Change the tint background for the switch
                (row.baseCell as! SwitchCell).switchControl.onTintColor = UIColor(named: "accent")
                // On switch listener
                row.onChange({ (row) in
                    // Change user defaults & update views
                    self.syncEnabled = row.value!
                    self.userDefaults.set(row.value, forKey: Settings.SYNC_ENABLED)
                    self.updateViews()
                })
            }
            <<< ButtonRow() { row in
                row.tag = Constants.SYNC_BUTTON_TAG
                row.title = Constants.SYNC_BUTTON_TITLE
                row.baseCell.tintColor = UIColor(named: "primary")
                row.onCellSelection({ (cell, row) in
                    if self.syncEnabled {
                        print("Syncing with Firebase")
                        DatabaseService.syncFirebase()
                    }
                })
            }
            <<< ButtonRow() { row in
                row.tag = Constants.IMPORT_BUTTON_TAG
                row.title = Constants.IMPORT_BUTTON_TITLE
                row.baseCell.tintColor = UIColor(named: "primary")
                row.onCellSelection({ (cell, row) in
                    if self.syncEnabled {
                        print("Importing from Firebase")
                        DatabaseService.importFromFirebase()
                    }
                })
            }
            <<< ButtonRow() { row in
                row.tag = Constants.SIGN_IN_OUT_BUTTON_TAG
                row.baseCell.tintColor = UIColor(named: "primary")
            }
        
        
        // TODO a delete all row?
        
        // Update views does the state configuration for the form
        updateViews()
    }
    
    // Initialize & launch Google's default sign-in UI
    private func signInPressed() {
        // Retrieve the authentication UI instance
        authUI = FUIAuth.defaultAuthUI()
        if let auth = authUI {
            // Set up providers
            auth.delegate = self
            auth.providers = [FUIGoogleAuth()]
            
            // Change styling of view controller & present it
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
            updateViews()
        } catch {
            print("Error trying to sign out: \(error)")
        }
    }
    
}
