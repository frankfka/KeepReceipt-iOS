//
//  UIServiec.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-10.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

// Methods to help manage UI
class UIService {
    
    // Show HUD with a given message for 2 seconds
    static func showHUDWithNoAction(isSuccessful: Bool, with message: String) {
        if(isSuccessful) {
            SVProgressHUD.showSuccess(withStatus: message)
        } else {
            SVProgressHUD.showError(withStatus: message)
        }
        SVProgressHUD.dismiss(withDelay: TimeInterval(2))
    }
    
    // Update size of a tableview such that there is no scrolling & all of its contents fit
    static func updateTableViewSize(tableView: UITableView, tableViewHeightConstraint: NSLayoutConstraint) {
        // We want to fit the entire tableview, so disable scroll
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Make tableview very big so that all the cells show
        tableViewHeightConstraint.constant = 1000
        UIView.animate(withDuration: 0, animations: {
            tableView.layoutIfNeeded()
        }) { (complete) in
            
            var heightOfTableView: CGFloat = 0.0
            // Get visible cells and sum up their heights
            let cells = tableView.visibleCells
            for cell in cells {
                heightOfTableView += cell.frame.height
            }
            // Update tableview height with new constant from the sum
            tableViewHeightConstraint.constant = heightOfTableView
        
        }
    }
    
    // Updates the size of a scrollview to fit all of its contents
    static func updateScrollViewSize(for scrollView: UIScrollView, with minHeight: CGFloat = CGFloat(integerLiteral: 0)) {
        
        // Sum up height of all the subviews
        var contentRect = CGRect.zero
        for view in scrollView.subviews {
            contentRect = contentRect.union(view.frame)
        }
        // Set scrollview size
        if minHeight > contentRect.size.height {
            scrollView.contentSize.height = minHeight
        } else {
            scrollView.contentSize = contentRect.size
        }
        
    }
    
}
