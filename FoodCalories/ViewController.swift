//
//  ViewController.swift
//  FoodCalories
//
//  Created by Jacky Tjoa on 2/9/15.
//  Copyright (c) 2015 Coolheart. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTF: UITextField!
    @IBOutlet weak var lblSearchResults: UILabel!
    @IBOutlet weak var noDataLbl: UILabel!
    
    private let realm = Realm()
    private let kTableHeaderHeight:CGFloat = 170.0
    private var searchTermGlobal:String = ""
    private var dataArray:[Food] = []
    private let refreshControl = UIRefreshControl()
    private var headerView:UIView!
    private var dataSourceIndex:Int!
    private var autocompleteTableView: UITableView!
    private var historySearchArray:[String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //header view
        self.headerView = self.tableView.tableHeaderView
        self.tableView.tableHeaderView = nil
        self.tableView.addSubview(self.headerView)
        self.tableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        self.tableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
        self.headerView.hidden = true
        
        //refresh control
        self.refreshControl.addTarget(self, action: "refreshTable", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        //double tap
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        self.tableView.addGestureRecognizer(doubleTapGesture)
        
        //auto complete
        let searchFrame = self.searchTF.frame
        self.autocompleteTableView = UITableView(frame: CGRectMake(
            searchFrame.origin.x,
            searchFrame.origin.y + searchFrame.size.height,
            self.view.frame.size.width - 16,
            120),
            style: UITableViewStyle.Plain)
        self.autocompleteTableView.dataSource = self
        self.autocompleteTableView.delegate = self
        self.autocompleteTableView.scrollEnabled = true
        self.autocompleteTableView.hidden = true
        self.headerView.addSubview(self.autocompleteTableView)
        
        //data source
        self.dataSourceIndex = kDataSourceHolmusk
        
        //no data
        self.noDataLbl.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateHeaderView()
        self.headerView.hidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions
    
    @IBAction func dataSourceChanged(sender: AnyObject) {
    
        let segment = sender as! UISegmentedControl
        self.dataSourceIndex = segment.selectedSegmentIndex
    }
    
    //MARK: - Refresh
    
    func refreshTable() {
    
        self.realm.write { () -> Void in
            
            self.realm.delete(self.realm.objects(Food))
        }
        
        loadData(self.searchTermGlobal)
    }
    
    //MARK: - UITapGesture
    
    func doubleTap(tap: UITapGestureRecognizer) {
    
        if tap.state == UIGestureRecognizerState.Ended {
        
            let point = tap.locationInView(tap.view)
            
            if self.tableView == nil {
            
                return
            }
            
            let indexPath = self.tableView.indexPathForRowAtPoint(point)!
            let food = self.dataArray[indexPath.row]
            
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FoodCell
            
            UIView.transitionWithView(cell.contentView, duration: 1.0, options: cell.isFront ? UIViewAnimationOptions.TransitionFlipFromLeft : UIViewAnimationOptions.TransitionFlipFromRight, animations: { () -> Void in
                
                if food.isFront {
                
                    cell.viewFront.hidden = true
                    cell.viewBack.hidden = false
                
                } else {
                
                    cell.viewFront.hidden = false
                    cell.viewBack.hidden = true
                }
                
            }, completion: { (finished) -> Void in
                
                if finished {

                    food.isFront = !food.isFront
                    
                    if !food.isFront {
                    
                        //is currently backside

                        if self.dataSourceIndex == kDataSourceKimonoLabs && food.dataSource == kDataSourceKimonoLabs {
                        
                            var searchURL = food.hrefLink.lastPathComponent
                            var URLSource = "http://www.kimonolabs.com/api/ondemand/6re1qqi2"
                            var params =
                                ["apikey":kKimonLabsApiKey,
                                    "kimpath3":searchURL]

                            let loader = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                            loader.labelText = "Loading data..."
                            
                            Alamofire.request(.GET, URLSource, parameters: params).responseJSON() {
                                (_, _, data, error) -> Void in

                                loader.hide(true)
                                
                                if let errorData = error {
                                    
                                    println(errorData.localizedDescription)
                                }
                                else
                                {
                                    let json = JSON(data!)
                                    //println(json)
                                    
                                    /*
                                    {
                                    "name" : "FatSecretNutrition",
                                    "results" : {
                                    "NutritionFacts" : [
                                    {
                                    "Sodium" : "123 mg",
                                    "CaloriesJoule" : "105 kj",
                                    "Serving" : "per 100 g",
                                    "Cholesterol" : "0.6 g",
                                    "Calories" : "",
                                    "Fat" : "0.3 g"
                                    }
                                    ],
                                    "Fat" : [
                                    {
                                    "Polyunsaturated" : "0 mg",
                                    "Saturated" : "0 mg",
                                    "Monounsaturated" : "5.7 g"
                                    }
                                    ],
                                    "Food" : [
                                    {
                                    "FoodName" : "Rose-Apples"
                                    }
                                    ]
                                    },
                                    "count" : 3,
                                    "url" : "http:\/\/www.fatsecret.com.sg\/calories-nutrition\/generic\/rose-apples"
                                    }
                                    */
                                    
                                    let realm = Realm()
                                    realm.write { //write begin
                                        
                                        let nutritionData = json["results"]["NutritionFacts"][0]
                                        
                                        //Sub-sections of 'Fat'
                                        
                                        let fatData = json["results"]["Fat"][0]
                                        
                                        if(fatData["Saturated"])
                                        {
    
                                            food.fat_saturated = fatData["Saturated"].string!
                                        }
                                        
                                        if(fatData["Polyunsaturated"])
                                        {
                                            food.fat_polyunsaturated = fatData["Polyunsaturated"].string!
                                        }
                                        
                                        if(fatData["Monounsaturated"])
                                        {
                                            food.fat_monosaturated = fatData["Monounsaturated"].string!
                                        }
                                        //====
                                        
                                        
                                        if(nutritionData["Cholesterol"])
                                        {
                                            food.cholesterol = nutritionData["Cholesterol"].string!
                                        }
                                        
                                        if(nutritionData["Sodium"])
                                        {
                                            food.sodium = nutritionData["Sodium"].string!
                                        }
                                        
                                        
                                        //Sub-sections of 'Carbohydrate'
                                        
                                        let carboData = json["results"]["Carbohydrate"][0]
                                        
                                        if(carboData["Fiber"])
                                        {
                                            food.fibre = carboData["Fiber"].string!
                                        }
                                        
                                        if(carboData["Sugar"])
                                        {
                                            food.sugar = carboData["Sugar"].string!
                                        }
                                        
                                        //====
                                                                                
                                        //refresh
                                        cell.loadNutritionData()
                                        
                                    }//write end
                                }//else no error
                            }//end responseJSON
                        }
                        else {
                            
                            cell.loadNutritionData()
                        }
                    }
                }
            })
        }
    }
    
    //MARK: - Helpers
    
    func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: tableView.bounds.width, height: kTableHeaderHeight)
        if self.tableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = self.tableView.contentOffset.y
            headerRect.size.height = -self.tableView.contentOffset.y
        }
        
        self.headerView.frame = headerRect
    }
    
    func loadData(searchTerm:String) {
    
        self.dataArray.removeAll(keepCapacity: true)//remove current data
        
        let predicate = NSPredicate(format: "name BEGINSWITH [c]%@", searchTerm)
        let results = realm.objects(Food).filter(predicate)

        if results.count > 0 {
            
            //If data exist in local database
            
            self.noDataLbl.hidden = true
            
            for food in results {
            
                self.dataArray.append(food)
            }
            
            self.tableView.reloadData()
        
        } else {
        
            //Otherwise, pull from network
            
            //default to holmusk
            var URLSource = "http://test.holmusk.com/food/search"
            var params = ["q":searchTerm]
            
            if self.dataSourceIndex == kDataSourceKimonoLabs {
            
                //kimonolabs
                URLSource = "https://www.kimonolabs.com/api/ondemand/1uv7lfx2"
                params = ["apikey":kKimonLabsApiKey, "q":searchTerm]
            }
            
            //let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            //configuration.timeoutIntervalForRequest = 102 // seconds
            //let manager = Alamofire.Manager(configuration: configuration)
            
            let loader = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loader.labelText = "Loading data..."
            
            Alamofire.request(.GET, URLSource, parameters: params).responseJSON() {
                (_, _, data, error) -> Void in
                
                self.refreshControl.endRefreshing()
                loader.hide(true)
                
                if error != nil {
                    
                    print("error fetch data: \(error?.localizedDescription)\n")
                    
                } else {
                    
                    let json = JSON(data!)
                    
                    if self.dataSourceIndex == kDataSourceHolmusk {
                    
                        self.realm.write({ () -> Void in

                            for jsonDict in json {
                            
                                print("jsonDict:\(jsonDict)\n")
                                
                                let foodName = jsonDict.1["name"].string!
                                let portions = jsonDict.1["portions"]
                                
                                for foodDict in portions {

                                    let food = Food()
                                    food.name = foodName
                                    food.dataSource = kDataSourceHolmusk
                                    food.serving = foodDict.1["name"].string!
                                    
                                    let importantNutrients = foodDict.1["nutrients"]["important"]
                                    
                                    if importantNutrients["calories"] != nil {
                                        food.calories = String(importantNutrients["calories"]["value"].intValue) + " " + importantNutrients["calories"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["total_fats"] != nil {
                                        food.fat = String(importantNutrients["total_fats"]["value"].intValue) + " " + importantNutrients["total_fats"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["saturated"] != nil {
                                        food.fat_saturated = String(importantNutrients["saturated"]["value"].intValue) + " " + importantNutrients["saturated"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["polyunsaturated"] != nil {
                                        food.fat_polyunsaturated = String(importantNutrients["polyunsaturated"]["value"].intValue) + " " + importantNutrients["polyunsaturated"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["monounsaturated"] != nil {
                                        food.fat_monosaturated = String(importantNutrients["monounsaturated"]["value"].intValue) + " " + importantNutrients["monounsaturated"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["cholesterol"] != nil {
                                        food.cholesterol = String(importantNutrients["cholesterol"]["value"].intValue) + " " + importantNutrients["cholesterol"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["sodium"] != nil {
                                        food.sodium = String(importantNutrients["sodium"]["value"].intValue) + " " + importantNutrients["sodium"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["total_carbs"] != nil {
                                        food.carbohydrate = String(importantNutrients["total_carbs"]["value"].intValue) + " " + importantNutrients["total_carbs"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["dietary_fibre"] != nil {
                                        food.fibre = String(importantNutrients["dietary_fibre"]["value"].intValue) + " " + importantNutrients["dietary_fibre"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["sugar"] != nil {
                                        food.sugar = String(importantNutrients["sugar"]["value"].intValue) + " " + importantNutrients["sugar"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["protein"] != nil {
                                        food.protein = String(importantNutrients["protein"]["value"].intValue) + " " + importantNutrients["protein"]["unit"].string!
                                    }
                                    
                                    if importantNutrients["potassium"] != nil {
                                        food.potassium = String(importantNutrients["potassium"]["value"].intValue) + " " + importantNutrients["potassium"]["unit"].string!
                                    }
                                    
                                    self.realm.add(food, update: false)
                                    self.dataArray.append(food)
                                }
                            }
                            
                            print("dataArray count: \(self.dataArray.count)\n")
                            
                            if self.dataArray.count == 0 {
                            
                                self.noDataLbl.hidden = false
                            }
                            else if self.dataArray.count > 0 {
                            
                                self.noDataLbl.hidden = true
                                self.loadImagesFromGoogleWithSearchTerm(searchTerm)
                            }
                        })//end write
                    }
                    else if self.dataSourceIndex == kDataSourceKimonoLabs {

                        self.realm.write({ () -> Void in
                            
                            for foodDict in json["Food"] {
                                
                                let food = Food()
                                food.dataSource = kDataSourceKimonoLabs
                                food.name = foodDict.1["name"]["text"].string!
                                food.serving = foodDict.1["serving"]["text"].string!
                                food.calories = foodDict.1["calories"]["text"].string!
                                food.fat = foodDict.1["fat"]["text"].string!
                                food.carbohydrate = foodDict.1["carbs"]["text"].string!
                                food.protein = foodDict.1["protein"]["text"].string!
                                food.hrefLink = foodDict.1["name"]["href"].string!
                                
                                self.realm.add(food, update: false)
                                self.dataArray.append(food)
                            }
                            
                            if self.dataArray.count == 0 {
                                
                                self.noDataLbl.hidden = false
                            }
                            else if self.dataArray.count > 0 {
                                
                                self.noDataLbl.hidden = true
                                self.loadImagesFromGoogleWithSearchTerm(searchTerm)
                            }
                        })//end write
                    }
                    
                    //reload
                    self.tableView.reloadData()
                    
                }//end else
            }//end Alamofire request
            
        }//end else
    }
    
    func loadImagesFromGoogleWithSearchTerm(searchTerm:String) {
    
        //Google Images
        Alamofire.request(.GET, "https://www.googleapis.com/customsearch/v1",
            parameters:
            ["key": "AIzaSyAXTN_pC9N-I_H-ko2vvgDjxgd2DPLu5Mk",
                "cx":"018231649527957198634:l9uospo7pa0",
                "searchType":"image",
                "q":searchTerm]).responseJSON() {
                    
                    (_, _, data, _) in
                    
                    let json = JSON(data!)
                    
                    let itemArray = json["items"]
                    print("itemArray count: \(itemArray.count)\n")
                    
                    var imageLinkArray:[String] = []
        
                    for itemDict in itemArray {
                        
                        let imageLink = itemDict.1["image"]["thumbnailLink"].string!
                        imageLinkArray.append(imageLink)
                    }
                    
                    //update Food object
                    self.realm.write({ () -> Void in

                        var i:Int = 0
                        for food:Food in self.dataArray {
                        
                            var idx = i % imageLinkArray.count
                            
                            let imgLink = imageLinkArray[idx]
                            food.imageLink = imgLink
                            
                            i++
                        }
                        
                        self.tableView.reloadData()
                    })

        }//end responseJSON
    }

    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.autocompleteTableView != nil {
        
            if tableView == self.autocompleteTableView {
            
                return self.historySearchArray.count
            }
        }
        
        self.lblSearchResults.text = "Search Results for: \(self.searchTermGlobal) (\(self.dataArray.count) results)"
        
        return self.dataArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if tableView == self.autocompleteTableView {
        
            return 24.0
        }
        
        return tableView.rowHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var masterCell:UITableViewCell!
        
        if tableView == self.autocompleteTableView {
        
            let identifier = "AutoCompleteCellIdentifier"
            
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: identifier)
            }

            //data
            if indexPath.row < self.historySearchArray.count {
                let searchString = self.historySearchArray[indexPath.row]
                cell!.textLabel?.text = searchString
            }
            
            masterCell = cell
        }
        else if tableView == self.tableView {
        
            let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier", forIndexPath: indexPath) as! FoodCell
            
            //data
            if indexPath.row < self.dataArray.count {
            
                let food = self.dataArray[indexPath.row] as Food
                cell.food = food

                if food.isFront {
                    cell.viewFront.hidden = false
                    cell.viewBack.hidden = true
                    
                } else {
                    
                    cell.viewFront.hidden = true
                    cell.viewBack.hidden = false
                }
                
                //front view
                cell.lblName.text = "per \(food.serving)"
                cell.lblCals.text = food.calories
                cell.lblFat.text = food.fat
                cell.lblCarbs.text = food.carbohydrate
                cell.lblProt.text = food.protein
                
                //back view
                cell.lblBackServings.text = cell.lblName.text
                
                //image
                let thumbLink = food.imageLink
                
                Alamofire.request(.GET, thumbLink).responseImage() {
                    (request, _, image, error) in
                    
                    if error == nil && image != nil {
                        
                        cell.bgImgView?.image = image
                        cell.backBgImgView.image = image
                    }
                    else
                    {
                        println("error image: " + error!.localizedDescription)
                    }
                }//end responseImage
            }
            
            masterCell = cell
        }

        return masterCell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView == self.autocompleteTableView {
        
            self.searchTF.resignFirstResponder()
            self.dismissAutocompleteTableView()
            
            let searchString = self.historySearchArray[indexPath.row]
            self.searchTF.text = searchString
            self.searchTermGlobal = searchString
            
            self.loadData(searchString)
        }
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //sticky header
        
        updateHeaderView()
        
        self.searchTF.resignFirstResponder()
        
        /*
        //parallax effect (not working...)
        let visibleCells = self.tableView.visibleCells() as! [FoodCell]
        
        for cell in visibleCells {
        
            //cell.cellOnTableView(self.tableView, view: self.view)
        
            cell.adjust(cell.frame.origin.y - scrollView.contentOffset.y)
        }
        */
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        self.refreshControl.endRefreshing()
        
        let searchString = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        if count(searchString) > 0 {
            self.showAutocompleteTableView(searchString)
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let searchString = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var substring = NSString(string: searchString)
        substring = substring.stringByReplacingCharactersInRange(range, withString: string)
        
        if substring.length == 0 {
        
            self.autocompleteTableView.hidden = true
        
        } else {
        
            self.showAutocompleteTableView(String(substring))
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField.returnKeyType == UIReturnKeyType.Search {
        
            textField.resignFirstResponder()
            self.dismissAutocompleteTableView()
            
            let searchString = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            
            if count(searchString) == 0 {
            
                let alertController = UIAlertController(title: "Invalid", message: "Please enter your search term", preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
                alertController.addAction(action)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            
            } else {
                
                //global variable
                self.searchTermGlobal = searchString
            
                //check existing history
                let predicate = NSPredicate(format: "searchString == [c]%@", searchString)
                let results = self.realm.objects(SearchHistory).filter(predicate)
                
                if results.count == 0 {
                
                    //save if search term does not exist in database
                    self.realm.write({ () -> Void in
                        
                        let searchHistory = SearchHistory()
                        searchHistory.searchString = searchString
                        self.realm.add(searchHistory, update: false)
                    })
                }

                self.loadData(searchString)
                
            } // end else
        } // end if
        
        return true
    }
    
    //MARK: - Search helper
    
    func getSearchHistory(searchString: String) -> [String] {
    
        var historyArray:[String] = []
        let predicate = NSPredicate(format: "searchString BEGINSWITH [c]%@", searchString)
        let results = self.realm.objects(SearchHistory).filter(predicate).sorted("searchString")
        
        let limit = 10
        var i = 0
        
        for result in results {
            
            if i < 10 {
                historyArray.append(result.searchString)
                i++
            }
        }
        
        return historyArray
    }
    
    func showAutocompleteTableView(searchString: String) {
    
        self.historySearchArray = self.getSearchHistory(searchString)
        
        if self.historySearchArray.count == 0 {
            self.autocompleteTableView.hidden = true
        }
        else if self.historySearchArray.count > 0 {
            self.autocompleteTableView.alpha = 1.0
            self.autocompleteTableView.hidden = false
        }
        
        self.autocompleteTableView.reloadData()
    }
    
    func dismissAutocompleteTableView() {
    
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            
            self.autocompleteTableView.alpha = 0.0
            
            }, completion: { (finished) -> Void in
                
        })
    }
}

//MARK: - Extensions

extension Alamofire.Request {
    public static func imageResponseSerializer() -> GenericResponseSerializer<UIImage> {
        return GenericResponseSerializer { request, response, data in
            if data == nil {
                return (nil, nil)
            }
            
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            
            return (image, nil)
        }
    }
    
    public func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
}

