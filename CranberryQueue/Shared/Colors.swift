//
//  Colors.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/22/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import Foundation
import UIKit

class Colors {
    static let genericTop = UIColor(red: 178.0 / 255.0, green: 86.0 / 255.0, blue: 86.0 / 255.0, alpha: 1.0)
    static let genericMiddle = UIColor(red: 190.0 / 255.0, green: 123.0 / 255.0, blue: 123.0 / 255.0, alpha: 1.0)
    static let genericBottom = UIColor(red: 46.0 / 255.0, green: 46.0 / 255.0, blue: 46.0 / 255.0, alpha: 1.0)
    
    static let border = UIColor(red: 85.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
    
    static let colorDark = UIColor(red: 73.0 / 255.0, green: 71.0 / 255.0, blue: 71.0 / 255.0, alpha: 1.0)
    static let colorLight = UIColor(red: 48.0 / 255.0, green: 65.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)
    
    static var mapGradient = gradientFromColors(
        top: genericTop,
        middle: genericMiddle,
        bottom: genericBottom,
        locations: [0.0, 0.4, 1.0]
    )
    
    static var queueGradient = gradientFromColors(
        top: genericTop,
        middle: genericMiddle,
        bottom: genericBottom,
        locations: [0.0, 0.4, 1.0]
    )
    
    /**
     Initializes a gradient with options
     - Parameter top: The upper color.
     - Parameter bottom: The lower color.
     - Parameter locations: The positions of the colors [1].
     - Returns: Gradient using the above options.
    */
    static func gradientFromColors(top: UIColor, middle: UIColor, bottom: UIColor, locations: [NSNumber]) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [top.cgColor, middle.cgColor, bottom.cgColor]
        gradient.locations = locations
        return gradient
    }
}
