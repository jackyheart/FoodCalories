//
//  Food.swift
//  FoodCalories
//
//  Created by Jacky Tjoa on 2/9/15.
//  Copyright (c) 2015 Coolheart. All rights reserved.
//

import Foundation
import RealmSwift

class Food: Object {
   
    dynamic var name:String = ""
    dynamic var serving:String = ""
    dynamic var calories:String = ""
    dynamic var fat:String = ""
    dynamic var fat_saturated:String = ""
    dynamic var fat_polyunsaturated:String = ""
    dynamic var fat_monosaturated:String = ""
    dynamic var cholesterol:String = ""
    dynamic var sodium:String = ""
    dynamic var carbohydrate:String = ""
    dynamic var fibre:String = ""
    dynamic var sugar:String = ""
    dynamic var protein:String = ""
    dynamic var potassium:String = ""
}