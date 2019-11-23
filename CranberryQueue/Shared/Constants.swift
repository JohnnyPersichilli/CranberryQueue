//
//  Constants.swift
//  CranberryQueue
//
//  Created by Carl Reiser on 10/27/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import Foundation
import GoogleMaps

struct Constants {
    static let stateDictionary: [String : String] = [
        "AK" : "Alaska",
        "AL" : "Alabama",
        "AR" : "Arkansas",
        "AS" : "American Samoa",
        "AZ" : "Arizona",
        "CA" : "California",
        "CO" : "Colorado",
        "CT" : "Connecticut",
        "DC" : "District of Columbia",
        "DE" : "Delaware",
        "FL" : "Florida",
        "GA" : "Georgia",
        "GU" : "Guam",
        "HI" : "Hawaii",
        "IA" : "Iowa",
        "ID" : "Idaho",
        "IL" : "Illinois",
        "IN" : "Indiana",
        "KS" : "Kansas",
        "KY" : "Kentucky",
        "LA" : "Louisiana",
        "MA" : "Massachusetts",
        "MD" : "Maryland",
        "ME" : "Maine",
        "MI" : "Michigan",
        "MN" : "Minnesota",
        "MO" : "Missouri",
        "MS" : "Mississippi",
        "MT" : "Montana",
        "NC" : "North Carolina",
        "ND" : " North Dakota",
        "NE" : "Nebraska",
        "NH" : "New Hampshire",
        "NJ" : "New Jersey",
        "NM" : "New Mexico",
        "NV" : "Nevada",
        "NY" : "New York",
        "OH" : "Ohio",
        "OK" : "Oklahoma",
        "OR" : "Oregon",
        "PA" : "Pennsylvania",
        "PR" : "Puerto Rico",
        "RI" : "Rhode Island",
        "SC" : "South Carolina",
        "SD" : "South Dakota",
        "TN" : "Tennessee",
        "TX" : "Texas",
        "UT" : "Utah",
        "VA" : "Virginia",
        "VI" : "Virgin Islands",
        "VT" : "Vermont",
        "WA" : "Washington",
        "WI" : "Wisconsin",
        "WV" : "West Virginia",
        "WY" : "Wyoming"
    ]
    
    static func aboutUsBlurb() -> NSAttributedString {
        let text0 = NSAttributedString(
            string: "\n\nDeveloped by four Engineers at Villanova University.\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let text1 = NSAttributedString(
            string: "\n\nCarl Reiser\nJohnny Persichilli\nMatt Innocenzo\nRolf Locher\n\n\n",
            attributes: [
                .paragraphStyle: paragraph,
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.white
            ]
        )
        let text2 = NSAttributedString(
            string: "Enjoy using our senior Capstone to explore music in your community and around the world. We hope you find the app as useful as we do when listening to music with friends.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
        )
        let text3 = NSAttributedString(
            string: "Built with Spotify SDK 1.0.2, Google Maps SDK 3.6.0, and Firebase SDK 6.13.0",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
        )
        let result = NSMutableAttributedString()
        
        result.append(text0)
        result.append(text2)
        result.append(text1)
        result.append(text3)
        
        return result
    }
    
    static func faqBlurb() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let titleSize: CGFloat = 13
        let answerSize: CGFloat = 12
        let text0 = NSAttributedString(
            string: "\n\nHow do I create a queue?",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: titleSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text1 = NSAttributedString(
            string: "\n\tYou can create a queue by tapping the plus icon in the Map screen, but you will need the Spotify app installed on your phone to continue.\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: answerSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text2 = NSAttributedString(
            string: "How do I join a queue?",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: titleSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text3 = NSAttributedString(
            string: "\n\tTapping a queue marker on the Map screen will bring up details about the queue. If you are close enough to the marker, select the green join button.\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: answerSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text4 = NSAttributedString(
            string: "Spotify could not connect?",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: titleSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text5 = NSAttributedString(
            string: "\n\tSometimes you need to close the Spotify app before you can successfully create a queue. This is due to issues between Spotify SDK and Apple iOS.\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: answerSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text6 = NSAttributedString(
            string: "Where are all the queues?",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: titleSize),
                .foregroundColor: UIColor.white
            ]
        )
        let text7 = NSAttributedString(
            string: "\n\tThis app has only been released to a few individuals - if you don’t see any queues in your area then create a queue and get the party started!",
            attributes: [
                .font: UIFont.systemFont(ofSize: answerSize),
                .foregroundColor: UIColor.white
            ]
        )
        let texts = [text0, text1, text2, text3, text4, text5, text6, text7]
        for text in texts { result.append(text) }
        return result
    }
    
    static func legalBlurb() -> NSAttributedString {
        return NSAttributedString(
            string: GMSServices.openSourceLicenseInfo(),
            attributes: [
                .foregroundColor: UIColor.white
            ]
        )
    }
    
    static func bugReportBlurb() -> NSAttributedString {
        return NSAttributedString(
            string: "\n\nUntil the offical release, bug reporting should be done through the TestFlight app.\n\nThanks for helping us improve.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
        )
    }
}
