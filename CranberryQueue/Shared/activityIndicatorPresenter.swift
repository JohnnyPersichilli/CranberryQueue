//
//  activityIndicatorPresenter.swift
//  CranberryQueue
//
//  Created by Matt Innocenzo on 9/30/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import Foundation

public protocol activityIndicatorPresenter {

    /// The activity indicator
    var activityIndicator: UIActivityIndicatorView { get }

    /// Show the activity indicator in the view
    func showActivityIndicator()

    /// Hide the activity indicator in the view
    func hideActivityIndicator()
}

public extension activityIndicatorPresenter where Self: UIViewController {

    func showActivityIndicator() {
        DispatchQueue.main.async {

            self.activityIndicator.style = .whiteLarge
            self.activityIndicator.frame = CGRect(x: 50, y: 50, width: 160, height: 160) //or whatever size you would like
            self.activityIndicator.transform = CGAffineTransform(scaleX: 3, y: 3)
            self.activityIndicator.color = .green
            self.activityIndicator.center = CGPoint(x: self.view.bounds.size.width / 2, y: self.view.bounds.height / 2)
            self.view.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
        }
    }

    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
}
