//
//  AnalyticsViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-12.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyPickerPopover

class AnalyticsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Date variables
    var today: Date?
    var dateInMonthToDisplayInfoFor: Date?
    var lastOfDisplayMonth: Date?
    var firstOfDisplayMonth: Date?
    var displayMonthQueryPredicates: [NSPredicate]?
    
    // Picker arrays
    var yearOptions: [String]?
    var monthOptions = Array(1...12)
    var monthDisplayOptions: [String]?
    
    // Realm / Database / Utils
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var categories: Results<Category>?
    var receipts: Results<Receipt>?
    let utilCalendar = Calendar(identifier: .gregorian)

    // UI Variables
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var displayMonthSpendLabel: UILabel!
    @IBOutlet weak var categoryBreakdownTable: UITableView!
    @IBOutlet weak var categoryBreakdownTableHeight: NSLayoutConstraint!
    @IBOutlet weak var displayMonthLabel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize all the dates
        today = Date()
        dateInMonthToDisplayInfoFor = today // For now we just show current month
        let currentYear = utilCalendar.dateComponents([.year], from: today!).year!
        
        // Arrays for use in picker
        yearOptions = Array(2000...currentYear).map({ (year) -> String in
            return "\(year)"
        }).reversed()
        monthOptions = Array(1...12)
        monthDisplayOptions = monthOptions.map({ (monthCode) -> String in
            return TextFormatService.getMonthString(for: monthCode, fullMonth: false)
        })
        
        // Initialize realm
        categories = realm.objects(Category.self)
        receipts = realm.objects(Receipt.self)
        
        // Tableview initialization
        categoryBreakdownTable.delegate = self
        categoryBreakdownTable.dataSource = self
        
        categoryBreakdownTable.register(UINib(nibName: "CategoryAnalyticsTableViewCell", bundle: nil), forCellReuseIdentifier: "CategoryAnalyticsCell")
        
        loadViews()
        
    }
    
    // So that numbers update when we switch from another view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadViews()
    }
    
    private func loadViews() {
        
        let currentDateComponents = utilCalendar.dateComponents([.year, .month], from: dateInMonthToDisplayInfoFor!)
        displayMonthLabel.setTitle(TextFormatService.getMonthString(for: currentDateComponents.month!, fullMonth: true), for: .normal)
        firstOfDisplayMonth = utilCalendar.date(from: currentDateComponents)
        lastOfDisplayMonth = utilCalendar.date(byAdding: .month, value: 1, to: firstOfDisplayMonth!) // Technically first of next month, but this is correct wrt the query
        
        displayMonthQueryPredicates = [
            // Greater than first of month
            NSPredicate(format: "transactionTime >= %@", NSDate(timeInterval: 0, since: firstOfDisplayMonth!)),
            // Less than last of month
            NSPredicate(format: "transactionTime < %@", NSDate(timeInterval: 0, since: lastOfDisplayMonth!))
        ]
        
        // Total spend this month
        let displayMonthQuery = NSCompoundPredicate(andPredicateWithSubpredicates: displayMonthQueryPredicates!)
        let totalSpend = AnalyticsService.getTotalSpend(for: receipts!.filter(displayMonthQuery))
        displayMonthSpendLabel.text = TextFormatService.getCurrencyString(for: totalSpend)
        
        // Make tableview full height & non-scrollable
        categoryBreakdownTable.reloadData()
        UIService.updateTableViewSize(tableView: categoryBreakdownTable, tableViewHeightConstraint: categoryBreakdownTableHeight)
        UIService.updateScrollViewSize(for: mainScrollView)
        
    }
    
    // MARK: Tableview Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryAnalyticsCell") as! CategoryAnalyticsTableViewCell
        let category = categories![indexPath.row]
        
        // Compute totals for each category
        var thisMonthQueryPredicatesWithCategory = [NSPredicate(format: "ANY categories.name == '\(category.name!)'")]
        thisMonthQueryPredicatesWithCategory.append(contentsOf: displayMonthQueryPredicates!)
        let thisMonthQueryWithCategory = NSCompoundPredicate(andPredicateWithSubpredicates: thisMonthQueryPredicatesWithCategory)
        let totalCategorySpendInMonth = AnalyticsService.getTotalSpend(for: receipts!.filter(thisMonthQueryWithCategory))
        
        cell.initializeUI(for: category.name ?? "", with: totalCategorySpendInMonth)
        return cell
    }
    
    // MARK: Button / Display Month Stuff
    @IBAction func displayMonthButtonPressed(_ sender: UIButton) {
        ColumnStringPickerPopover(title: "Select a Date",
                                  choices: [monthDisplayOptions!,yearOptions!],
                                  selectedRows: [0,0], columnPercents: [0.5, 0.5])
            .setDoneButton(action: { popover, selectedRows, selectedStrings in
                print("selected rows \(selectedRows) strings \(selectedStrings)")
            })
            .setFontSizes([CGFloat(integerLiteral: 20), CGFloat(integerLiteral: 20)])
            .appear(originView: sender, baseViewController: self)
    }
    
    

}
