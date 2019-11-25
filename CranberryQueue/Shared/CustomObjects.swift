//
//  CustomObjects.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import Foundation

struct Song {
    var name = String()
    var artist = String()
    var imageURL = String()
    var docID = String()
    var votes = 0
    var uri = String()
    var next = false
    var timestamp = Int()
}

struct CQLocation {
    var name = String()
    var city = String()
    var region = String()
    var long = Double()
    var lat = Double()
    var queueId = String()
    var numMembers = Int()
}

struct PlaybackInfo {
    var name = String()
    var artist = String()
    var imageURL = String()
    var position = Int()
    var duration = Int()
    var isPaused = Bool()
    var timestamp = Int()
    var uri = String()
}

extension Song: Equatable {
    static func == (left: Song, right: Song) -> Bool {
        return left.docID == right.docID
    }
}
