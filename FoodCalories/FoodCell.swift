//
//  FoodCell.swift
//  FoodCalories
//
//  Created by Jacky Tjoa on 2/9/15.
//  Copyright (c) 2015 Coolheart. All rights reserved.
//

import UIKit

class FoodCell: UITableViewCell, UITableViewDataSource {

    @IBOutlet weak var viewFront: UIView!
    @IBOutlet weak var viewBack: UIView!
    @IBOutlet weak var viewBackContainer: UIView!
    @IBOutlet weak var lblCals: UILabel!
    @IBOutlet weak var lblFat: UILabel!
    @IBOutlet weak var lblCarbs: UILabel!
    @IBOutlet weak var lblProt: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var bgImgView: UIImageView!
    @IBOutlet weak var nutritionTableView: UITableView!
    @IBOutlet weak var lblBackServings: UILabel!
    @IBOutlet weak var backBgImgView: UIImageView!
    
    private var leftColumn:[[String:String]] = []
    private var rightColumn:[[String:String]] = []
    var isFront:Bool = true
    var food:Food!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //border
        let color:CGFloat = 200.0
        self.viewFront.layer.borderColor = UIColor(red: color/255.0, green: color/255.0, blue: color/255.0, alpha: 1.0).CGColor
        self.viewFront.layer.borderWidth = 0.5
        
        self.viewBack.layer.borderColor = UIColor(red: color/255.0, green: color/255.0, blue: color/255.0, alpha: 1.0).CGColor
        self.viewBack.layer.borderWidth = 0.5
        
        self.nutritionTableView.layer.borderColor = UIColor(red: color/255.0, green: color/255.0, blue: color/255.0, alpha: 1.0).CGColor
        self.nutritionTableView.layer.borderWidth = 0.5

        //shadow
        let view = self.viewFront
        let shadowPath = UIBezierPath(rect: view.layer.bounds)
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.blackColor().CGColor
        view.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10.0
        view.layer.shadowPath = shadowPath.CGPath
        
        /*
        let viewBack = self.viewBack
        let shadowPathBack = UIBezierPath(rect: viewBack.layer.bounds)
        viewBack.layer.masksToBounds = false
        viewBack.layer.shadowColor = UIColor.blackColor().CGColor
        viewBack.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        viewBack.layer.shadowOpacity = 0.1
        viewBack.layer.shadowRadius = 10.0
        viewBack.layer.shadowPath = shadowPathBack.CGPath
        */
        
        //nutrition table view
        self.nutritionTableView.dataSource = self
        self.nutritionTableView.backgroundColor = UIColor.clearColor()
        
        //blur effect
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        
        //blur view
        let blurView: UIVisualEffectView = UIVisualEffectView(effect: blurEffect)
        //blurView.setTranslatesAutoresizingMaskIntoConstraints(false)
        blurView.frame = CGRectMake(
            0.0,
            0.0,
            UIScreen.mainScreen().bounds.width - 34,
            self.viewBackContainer.frame.height)
        //self.viewBackContainer.addSubview(blurView)
        self.viewBackContainer.insertSubview(blurView, atIndex: 0)
        
        //vibrancy view
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        vibrancyView.setTranslatesAutoresizingMaskIntoConstraints(false)
        vibrancyView.bounds = blurView.bounds
        blurView.contentView.addSubview(vibrancyView)

        //background
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - Custom
    
    func cellOnTableView(tableView: UITableView, view:UIView) {
    
        let rectInSuperView = tableView.convertRect(self.frame, toView: view)
        
        let distanceFromCenter = CGRectGetHeight(view.frame) * 0.5 - CGRectGetMinY(rectInSuperView)
        let difference = CGRectGetHeight(self.bgImgView.frame) - CGRectGetHeight(self.frame)
        let move = (distanceFromCenter / CGRectGetHeight(view.frame)) * difference
        
        var imageRect = self.bgImgView.frame
        imageRect.origin.y = -(difference * 0.5) + move
        self.bgImgView.frame = imageRect
    }
    
    func adjust(offset: CGFloat) {
    
        let view = self.bgImgView
        
        var frame = view.frame
        frame.origin.y = offset * 0.2
        view.frame = frame
    }
    
    func loadNutritionData() {
    
        //load nutrition data
        self.leftColumn = [
            ["Calories":self.food.calories],
            ["Fat":self.food.fat],
            ["Saturated":self.food.fat_saturated],
            ["Poly":self.food.fat_polyunsaturated],
            ["Mono":self.food.fat_monosaturated],
            ["Chol":self.food.cholesterol]
        ]
        
        self.rightColumn = [
            ["Sodium":self.food.calories],
            ["Carbs":self.food.carbohydrate],
            ["Fibre":self.food.fibre],
            ["Sugar":self.food.sugar],
            ["Protein":self.food.protein],
            ["Potassium":self.food.potassium]
        ]
        
        self.nutritionTableView.reloadData()
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //left and right column has the same amount of data
        return self.leftColumn.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier", forIndexPath: indexPath) as! NutritionCell
        
        cell.backgroundColor = UIColor.clearColor()
        
        let leftData = self.leftColumn[indexPath.row] as [String:String]
        let rightData = self.rightColumn[indexPath.row] as [String:String]
        
        if leftData.keys.array.count > 0 && rightData.keys.array.count > 0 {
        
            let leftDataKey = leftData.keys.array[0]
            let rightDataKey = rightData.keys.array[0]
            
            let leftDataValue = leftData[leftDataKey]
            let rightDataValue = rightData[rightDataKey]
            
            cell.lblNutritionLeft.text = leftDataKey
            cell.lblValueLeft.text = leftDataValue
            
            cell.lblNutritionRight.text = rightDataKey
            cell.lblValueRight.text = rightDataValue
        }
        
        return cell
    }
}
