//
//  Tools.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/23.
//  Copyright © 2015年 koofrank. All rights reserved.
//

import UIKit
import SpriteKit

func randomInRange(range: Range<Int>) -> Int {
    let count = UInt32(range.endIndex - range.startIndex)
    return  Int(arc4random_uniform(count)) + range.startIndex
}

extension UIColor {
    class func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension SKAction {
    class func moveDistance(distance:CGVector, fadeInWithDuration duration:NSTimeInterval) -> SKAction {
        let fadeIn = SKAction.fadeInWithDuration(duration)
        let moveIn = SKAction.moveBy(distance, duration: duration)
        return SKAction.group([fadeIn, moveIn])
    }
    
    class func moveDistance(distance:CGVector, fadeOutWithDuration duration:NSTimeInterval) -> SKAction {
        let fadeOut = SKAction.fadeOutWithDuration(duration)
        let moveOut = SKAction.moveBy(distance, duration: duration)
        return SKAction.group([fadeOut, moveOut])
    }
}