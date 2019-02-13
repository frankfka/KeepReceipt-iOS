//
//  AnalyticsViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-12.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import RealmSwift

class AnalyticsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Date variables
    var today: Date?
    var firstOfMonth: Date?
    var firstOfPrevMonth: Date?
    var lastOfPrevMonth: Date?
    var thisMonthQueryPredicates: [NSPredicate]?
    
    // Realm / Database
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var categories: Results<Category>?
    var receipts: Results<Receipt>?

    // UI Variables
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var thisMonthSpendLabel: UILabel!
    @IBOutlet weak var currentMonthTable: UITableView!
    @IBOutlet weak var currentMonthTableHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize all the dates
        let utilCalendar = Calendar(identifier: .gregorian)
        today = Date()
        let currentDateComponents = utilCalendar.dateComponents([.year, .month], from: today!)
        firstOfMonth = utilCalendar.date(from: currentDateComponents)
        if let firstOfCurrMonth = firstOfMonth {
            lastOfPrevMonth = utilCalendar.date(byAdding: .day, value: -1, to: firstOfCurrMonth)
            firstOfPrevMonth = utilCalendar.date(byAdding: .month, value: -1, to: firstOfCurrMonth)
        }
        thisMonthQueryPredicates = [
            // Greater than first of month
            NSPredicate(format: "transactionTime >= %@", NSDate(timeInterval: 0, since: firstOfMonth!)),
            // Less than last of month (plus one day to include last of month)
            NSPredicate(format: "transactionTime <= %@", NSDate(timeInterval: 86400, since: today!))
        ]
        
        // Initialize realm
        categories = realm.objects(Category.self)
        receipts = realm.objects(Receipt.self)
        
        // Tableview initialization
        currentMonthTable.delegate = self
        currentMonthTable.dataSource = self
        
        currentMonthTable.register(UINib(nibName: "CategoryAnalyticsTableViewCell", bundle: nil), forCellReuseIdentifier: "CategoryAnalyticsCell")
        
        loadViews()
        
    }
    
    // So that numbers update when we switch from another view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadViews()
    }
    
    private func loadViews() {
        
        // Total spend this month
        
        let thisMonthQuery = NSCompoundPredicate(andPredicateWithSubpredicates: thisMonthQueryPredicates!)
        let totalSpendThisMonth = AnalyticsService.getTotalSpend(for: receipts!.filter(thisMonthQuery))
        thisMonthSpendLabel.text = TextFormatService.getCurrencyString(for: totalSpendThisMonth)
        
        // Make tableview full height & non-scrollable
        UIService.updateTableViewSize(tableView: currentMonthTable, tableViewHeightConstraint: currentMonthTableHeight)
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
        thisMonthQueryPredicatesWithCategory.append(contentsOf: thisMonthQueryPredicates!)
        let thisMonthQueryWithCategory = NSCompoundPredicate(andPredicateWithSubpredicates: thisMonthQueryPredicatesWithCategory)
        let totalCategorySpendInMonth = AnalyticsService.getTotalSpend(for: receipts!.filter(thisMonthQueryWithCategory))
        
        cell.initializeUI(for: category.name ?? "", with: totalCategorySpendInMonth)
        return cell
    }
    

}
