//
//  AppDelegate.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

protocol RemoteDelegate: class {
    func updateConnectionStatus(connected: Bool)
}

protocol SessionDelegate: class {
    func updateSessionStatus(connected: Bool)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate {
    var window: UIWindow?
    
    weak var appPlayerDelegate: RemoteDelegate?
    weak var appMapDelegate: RemoteDelegate?
    weak var seshDelegate: SessionDelegate?
    
    let SpotifyClientID = "02294b5911c543599eb7fb37d1ed2d39"
    let SpotifyRedirectURL = URL(string: "CranberryQueue://spotify-login-callback")!
    
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyClientID,
        redirectURL: SpotifyRedirectURL
    )
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "https://cranberryqueue.herokuapp.com/api/token"),
            let tokenRefreshURL = URL(string: "https://cranberryqueue.herokuapp.com/api/refresh_token") {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    var token = ""
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        FirebaseApp.configure()
        GMSServices.provideAPIKey("AIzaSyAlD1H2m8hoYKp8wIzLLEN6AJtPqwhrOs0")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.sessionManager.application(app, open: url, options: options)
        
        return true
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        token = session.accessToken
        
        seshDelegate?.updateSessionStatus(connected: true)
    }
    
    func startAppRemote() {
        DispatchQueue.main.async {
            self.appRemote.connectionParameters.accessToken = self.token
            self.appRemote.delegate = self
            self.appRemote.connect()
        }
    }
    
    func pauseAndDisconnectAppRemote() {
        self.appRemote.playerAPI?.pause()
        self.appRemote.disconnect()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        seshDelegate?.updateSessionStatus(connected: false)
        print(error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print(session)
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("connected")
        appPlayerDelegate?.updateConnectionStatus(connected: true)
        appMapDelegate?.updateConnectionStatus(connected: true)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("disconnected")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("failed")
        /// player controller does not need to be notified of failure
        appMapDelegate?.updateConnectionStatus(connected: false)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if self.appRemote.isConnected {
            self.appRemote.disconnect()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let _ = self.appRemote.connectionParameters.accessToken {
            DispatchQueue.main.async {
                self.appRemote.delegate = self
                self.appRemote.connect()
            }
        }
    }
    
    func startSession() {
        let requestedScopes: SPTScope = [.appRemoteControl, .userModifyPlaybackState]
        self.sessionManager.initiateSession(with: requestedScopes, options: .default)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

