//
//  NutritionCell.swift
//  FoodCalories
//
//  Created by Jacky Tjoa on 3/9/15.
//  Copyright (c) 2015 Coolheart. All rights reserved.
//

import UIKit

class NutritionCell: UITableViewCell {

    @IBOutlet weak var lblNutritionLeft: UILabel!
    @IBOutlet weak var lblValueLeft: UILabel!
    @IBOutlet weak var lblNutritionRight: UILabel!
    @IBOutlet weak var lblValueRight: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
