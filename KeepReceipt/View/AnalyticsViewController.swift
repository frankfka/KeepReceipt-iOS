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
import Charts

class AnalyticsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Date variables
    var today: Date?
    var todayComponents: DateComponents?
    var lastOfDisplayMonth: Date?
    var firstOfDisplayMonth: Date?
    var displayMonthQueryPredicates: [NSPredicate]?
    
    // Picker arrays
    var yearOptions: [String]?
    var monthOptions: [String]?
    // We use indicies to have greater flexibility - can just retrieve the strings if needed
    var selectedMonthRow: Int?
    var selectedYearRow: Int?
    
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
    @IBOutlet weak var lineChartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize all the dates
        today = Date() // start displaying current month
        todayComponents = utilCalendar.dateComponents([.day, .month, .year], from: today!)
        let currentYear = todayComponents!.year!
        let currentMonth = todayComponents!.month!
        
        // Arrays for use in picker
        yearOptions = Array(2000...currentYear).map({ (year) -> String in
            return "\(year)"
        }).reversed()
        monthOptions = Array(1...12).map({ (monthCode) -> String in
            return TextFormatService.getMonthString(for: monthCode, fullMonth: false)
        })
        
        // Set initial selection for date picker
        selectedMonthRow = currentMonth - 1 // So that indicies start at 0
        selectedYearRow = 0
        
        // Initialize realm
        categories = realm.objects(Category.self).sorted(byKeyPath: "name", ascending: true)
        receipts = realm.objects(Receipt.self)
        
        // Tableview initialization
        categoryBreakdownTable.delegate = self
        categoryBreakdownTable.dataSource = self
        categoryBreakdownTable.register(UINib(nibName: "CategoryAnalyticsTableViewCell", bundle: nil), forCellReuseIdentifier: "CategoryAnalyticsCell")
        
        // Add border to button
        displayMonthLabel.layer.cornerRadius = 4
        displayMonthLabel.layer.borderWidth = 1
        displayMonthLabel.layer.borderColor = UIColor.init(named: "primary")!.cgColor
        
        loadViews()
        
    }
    
    // So that numbers update when we switch from another view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadViews()
    }
    
    private func loadViews() {
        
        let currentDateComponents = DateComponents(year: selectedYearRow! >= 0 ? Int(string: yearOptions![selectedYearRow!]) : todayComponents!.year!,
                       month: selectedMonthRow! >= 0 ? Int(selectedMonthRow! + 1) : todayComponents!.month!)
        firstOfDisplayMonth = utilCalendar.date(from: currentDateComponents)
        lastOfDisplayMonth = utilCalendar.date(byAdding: .month, value: 1, to: firstOfDisplayMonth!) // Technically first of next month, but this is correct wrt the query
        
        // Set display on the button
        displayMonthLabel.setTitle(TextFormatService.getMonthAndYearString(for: firstOfDisplayMonth!, fullMonth: false), for: .normal)
        
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
        
        // Calculate spends for previous few months & get middle-of-month time values
        // We'll use an extracted helper method in Analytics service to keep code clean
        var lineChartData: [ChartDataEntry] = [ChartDataEntry(x: getMiddleOfMonthDate(firstOfMonthDate: firstOfDisplayMonth!).timeIntervalSince1970, y: totalSpend)] // Initialized with this month
        // Now loop through prior months
        let maxMonthNumber = 4
        for monthIncrement in 1...maxMonthNumber {
            let firstOfMonth = utilCalendar.date(byAdding: .month, value: -monthIncrement, to: firstOfDisplayMonth!)!
            let lastOfMonth = utilCalendar.date(byAdding: .month, value: -monthIncrement, to: lastOfDisplayMonth!)!
            let monthlySpend = AnalyticsService.getTotalSpend(for: receipts!, startTime: firstOfMonth, endTime: lastOfMonth)
            
            lineChartData.append(ChartDataEntry(x: getMiddleOfMonthDate(firstOfMonthDate: firstOfMonth).timeIntervalSince1970, y: monthlySpend))
            
            // Add a dummy data point if this is the earliest month (required for a Chart library bug)
            if monthIncrement == maxMonthNumber {
                lineChartData.append(ChartDataEntry(x: getMiddleOfMonthDate(firstOfMonthDate: firstOfMonth).timeIntervalSince1970 - 1000, y: monthlySpend))
            }
        }
        
        // Create a new dataset from the prior spend data
        let lineChartDataset = LineChartDataSet(Array(lineChartData.reversed()))
        
        lineChartDataset.mode = .linear // Linear lines to join data poitns
        lineChartDataset.drawCircleHoleEnabled = false // Removes transparent hole for each datapoint
        lineChartDataset.setColor(NSUIColor(named: "accent")!) // Line color
        lineChartDataset.setCircleColor(NSUIColor(named: "primary")!) // Data point color
        lineChartDataset.lineWidth = 2
        lineChartDataset.circleRadius = 3
        lineChartDataset.drawValuesEnabled = false // Disable value text beside each datapoint
        // Line chart customization
        lineChartView.isUserInteractionEnabled = false // Disable all the dragging/zooming
        lineChartView.legend.enabled = false
        // Configure the xAxis
        let xAxis = lineChartView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = MonthValueFormatter() // Use a custom formatter that displays month & year
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 12)
        xAxis.avoidFirstLastClippingEnabled = true // Avoids clipping to bounds
        xAxis.setLabelCount(lineChartDataset.count - 1, force: true) // Force # labels to the # months
        // Configure the yAxis
        let yAxis = lineChartView.leftAxis
        yAxis.enabled = true
        yAxis.valueFormatter = CurrencyValueFormatter()
        yAxis.drawGridLinesEnabled = false
        yAxis.labelFont = UIFont.systemFont(ofSize: 12)
        lineChartView.rightAxis.enabled = false
        // Set the data for the line chart
        lineChartView.data = LineChartData(dataSet: lineChartDataset)
        
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
                                  choices: [monthOptions!,yearOptions!],
                                  selectedRows: [selectedMonthRow != nil ? selectedMonthRow! : 0, selectedYearRow != nil ? selectedYearRow! : 0],
                                  columnPercents: [0.5, 0.5])
            .setDoneButton(action: { popover, selectedRows, selectedStrings in
                // Initialize the selected rows & reload views
                self.selectedMonthRow = selectedRows[0]
                self.selectedYearRow = selectedRows[1]
                self.loadViews()
            })
            .setFontSizes([CGFloat(integerLiteral: 20), CGFloat(integerLiteral: 20)])
            .appear(originView: sender, baseViewController: self)
    }
    
    // Just add 15 days for now to approximate middle of month
    private func getMiddleOfMonthDate(firstOfMonthDate: Date) -> Date {
        return utilCalendar.date(byAdding: .day, value: 15, to: firstOfMonthDate)!
    }

}
