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

class ViewController: UIViewController, UITableViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var searchTerm:String = ""
    private var dataArray:[Food] = []
    private var imageLinkArray:[String] = []
    private var refreshControl = UIRefreshControl()
    private let kTableHeaderHeight:CGFloat = 170.0
    private var headerView:UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController!.hidesBarsOnSwipe = true;

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
        
        //load data
        self.searchTerm = "apple"
        loadData(searchTerm)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateHeaderView()
        self.headerView.hidden = false
                
        //var scrollView = UIScrollView()
        //self.scrollViewDidScroll(scrollView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Refresh
    
    func refreshTable() {
    
        let realm = Realm()
        
        realm.write { () -> Void in
            
            realm.delete(realm.objects(Food))
        }
        
        loadData(self.searchTerm)
    }
    
    //MARK: - UITapGesture
    
    func doubleTap(tap: UITapGestureRecognizer) {
    
        if tap.state == UIGestureRecognizerState.Ended {
        
            let point = tap.locationInView(tap.view)
            let indexPath = self.tableView.indexPathForRowAtPoint(point)!
            
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FoodCell
            
            UIView.transitionWithView(cell.contentView, duration: 1.0, options: cell.isFront ? UIViewAnimationOptions.TransitionFlipFromLeft : UIViewAnimationOptions.TransitionFlipFromRight, animations: { () -> Void in
                
                if cell.isFront {
                
                    cell.viewFront.hidden = true
                    cell.viewBack.hidden = false
                
                } else {
                
                    cell.viewFront.hidden = false
                    cell.viewBack.hidden = true
                }
                
            }, completion: { (finished) -> Void in
                
                if finished {
                
                    cell.isFront = !cell.isFront
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
    
        let realm = Realm()
        self.dataArray.removeAll(keepCapacity: true)//remove current data
        
        let predicate = NSPredicate(format: "name CONTAINS [c]%@", searchTerm)
        let results = realm.objects(Food).filter(predicate)

        if results.count > 0 {
            
            //If data exist in local database
            
            for food in results {
            
                self.dataArray.append(food)
            }
            
            self.tableView.reloadData()
        
        } else {
        
            //Otherwise, pull from network
            
            //kimonolabs
//            let URLSource = "https://www.kimonolabs.com/api/ondemand/1uv7lfx2"
//            let params = ["apikey":kKimonLabsApiKey, "q":searchTerm]
            
            //holmusk
            let URLSource = "http://test.holmusk.com/food/search"
            let params = ["q":searchTerm]
            let dataSourceType = kDataSourceHolmusk
            
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.timeoutIntervalForRequest = 102 // seconds
            let manager = Alamofire.Manager(configuration: configuration)
            
            Alamofire.request(.GET, URLSource, parameters: params).responseJSON() {
                (_, _, data, error) -> Void in
                
                if error != nil {
                    
                    print("error fetch data: \(error?.localizedDescription)\n")
                    
                } else {
                    
                    let json = JSON(data!)
                    
                    if dataSourceType == kDataSourceHolmusk {
                    
                        realm.write({ () -> Void in
                            
                            self.refreshControl.endRefreshing()
                            
                            for jsonDict in json {
                            
                                let foodName = jsonDict.1["name"].string!
                                let portions = jsonDict.1["portions"]
                                
                                for foodDict in portions {

                                    let food = Food()
                                    food.name = foodName
                                    food.serving = foodDict.1["name"].string!
                                    
                                    let importantNutrients = foodDict.1["nutrients"]["important"]
                                    
                                    food.calories = String(importantNutrients["calories"]["value"].intValue) + " " + importantNutrients["calories"]["unit"].string!
                                    
                                    food.fat = String(importantNutrients["total_fats"]["value"].intValue) + " " + importantNutrients["total_fats"]["unit"].string!
                                    
                                    food.fat_saturated = String(importantNutrients["saturated"]["value"].intValue) + " " + importantNutrients["saturated"]["unit"].string!
                                    
                                    food.fat_polyunsaturated = String(importantNutrients["polyunsaturated"]["value"].intValue) + " " + importantNutrients["polyunsaturated"]["unit"].string!
                                    
                                    food.fat_monosaturated = String(importantNutrients["monounsaturated"]["value"].intValue) + " " + importantNutrients["monounsaturated"]["unit"].string!
                                    
                                    food.cholesterol = String(importantNutrients["cholesterol"]["value"].intValue) + " " + importantNutrients["cholesterol"]["unit"].string!
                                    
                                    food.sodium = String(importantNutrients["sodium"]["value"].intValue) + " " + importantNutrients["sodium"]["unit"].string!
                                    
                                    food.carbohydrate = String(importantNutrients["total_carbs"]["value"].intValue) + " " + importantNutrients["total_carbs"]["unit"].string!
                                    
                                    food.fibre = String(importantNutrients["dietary_fibre"]["value"].intValue) + " " + importantNutrients["dietary_fibre"]["unit"].string!
                                    
                                    food.sugar = String(importantNutrients["sugar"]["value"].intValue) + " " + importantNutrients["sugar"]["unit"].string!
                                    
                                    food.protein = String(importantNutrients["protein"]["value"].intValue) + " " + importantNutrients["protein"]["unit"].string!
                                    
                                    food.potassium = String(importantNutrients["potassium"]["value"].intValue) + " " + importantNutrients["potassium"]["unit"].string!
                                    
                                    realm.add(food, update: false)
                                    self.dataArray.append(food)
                                }
                            }

                            print("dataArray count: \(self.dataArray.count)\n")
                            self.tableView.reloadData()
                        })
                    }
                    else if dataSourceType == kDataSourceKimonoLabs {

                        realm.write({ () -> Void in
                            
                            for foodDict in json["Food"] {
                                
                                let food = Food()
                                food.name = foodDict.1["name"]["text"].string!
                                food.serving = foodDict.1["serving"]["text"].string!
                                food.calories = foodDict.1["calories"]["text"].string!
                                food.fat = foodDict.1["fat"]["text"].string!
                                food.carbohydrate = foodDict.1["carbs"]["text"].string!
                                food.protein = foodDict.1["protein"]["text"].string!
                                
                                realm.add(food, update: false)
                                self.dataArray.append(food)
                            }
                        })
                    }
                    
                    self.tableView.reloadData()
                }//end else
            }//end Alamofire request
            
            //Google Images
            Alamofire.request(.GET, "https://www.googleapis.com/customsearch/v1",
                parameters:
                ["key": "AIzaSyAXTN_pC9N-I_H-ko2vvgDjxgd2DPLu5Mk",
                    "cx":"018231649527957198634:l9uospo7pa0",
                    "searchType":"image",
                    "q":searchTerm]).responseJSON() {
                        
                        (_, _, data, _) in
                        
                        //self.refreshControl.endRefreshing()
                        //MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        
                        let json = JSON(data!)
                        //println(json)
                        
                        let itemArray = json["items"]
                        print("itemArray count: \(itemArray.count)\n")
                        
                        for itemDict in itemArray {
                            
                            self.imageLinkArray.append(itemDict.1["image"]["thumbnailLink"].string!)
                        }
                        
                        self.tableView.reloadData()
                        
            }//end responseJSON
            
        }//end else
    }

    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.dataArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier", forIndexPath: indexPath) as! FoodCell
                
        if indexPath.row < self.dataArray.count {
        
            let food = self.dataArray[indexPath.row] as Food
            
            //data
            cell.food = food
            
            //front view
            cell.lblName.text = "per \(food.serving)"
            cell.lblCals.text = food.calories
            cell.lblFat.text = food.fat
            cell.lblCarbs.text = food.carbohydrate
            cell.lblProt.text = food.protein
            
            //back view
            cell.lblBackServings.text = cell.lblName.text
            
            //TODO: temp
            cell.loadNutritionData()
        }
        
        let imageIndex = indexPath.row % 10
        
        if imageIndex < self.imageLinkArray.count {
            
            let thumbLink = self.imageLinkArray[imageIndex] as String
        
            Alamofire.request(.GET, thumbLink).responseImage() {
                (request, _, image, error) in
                
                if error == nil && image != nil {
                    
                    cell.bgImgView?.image = image
                }
                else
                {
                    println("error" + error!.localizedDescription)
                }
            }//end responseImage
        }

        return cell
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        updateHeaderView()
        
        /*
        let visibleCells = self.tableView.visibleCells() as! [FoodCell]
        
        for cell in visibleCells {
        
            //cell.cellOnTableView(self.tableView, view: self.view)
        
            cell.adjust(cell.frame.origin.y - scrollView.contentOffset.y)
        }
        */
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

