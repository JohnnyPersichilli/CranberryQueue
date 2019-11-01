//
//  SegmentedViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/27/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

protocol SegmentedJointDelegate: class {
    func addSongTapped(song: Song)
}

protocol SegmentedChildDelegate: class {
    func clear()
}

class SegmentedViewController: UIViewController, QueueSegmentedDelegate {
    
    
    @IBOutlet var stackHorizontalConstraint: NSLayoutConstraint!
        
    @IBOutlet var searchContainerView: UIView!
    
    weak var jointDelegate: SegmentedJointDelegate?
    weak var childDelegate: SegmentedChildDelegate?
    
    var queueId: String?
    var uid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        guard let control = sender as? UISegmentedControl else {
            return
        }
        var newConstant: CGFloat
        switch control.selectedSegmentIndex {
        case 0:
            newConstant = 0
        case 1:
            newConstant = -self.view.frame.size.width
        default:
            newConstant = -2*self.view.frame.size.width
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.stackHorizontalConstraint.constant = newConstant
            self.view.layoutIfNeeded()
        }) { (val) in
            
        }
    }
    
    func searchTapped(shouldHideContents: Bool) {
        if shouldHideContents {
            childDelegate?.clear()
        }
        else {
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SearchController {
            /// swap delegates with SearchController
            let vc = segue.destination as? SearchController
            vc?.delegate = jointDelegate
            vc?.queueId = queueId
            vc?.uid = uid
            childDelegate = vc
        }
        else if false {
            
        }
        else if false {
            
        }
    }
}
