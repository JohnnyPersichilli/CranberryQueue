//
//  AppDelegate.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTSessionManagerDelegate {
    
    var token = String()
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        self.token = session.accessToken
        //self.appRemote.connect()
        print(session.accessToken)
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print(error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("0")
        
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("1")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("2")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("3")
    }
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let requestedScopes: SPTScope = [.appRemoteControl]
        self.sessionManager.initiateSession(with: requestedScopes, options: .default)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                //self.appRemote.authorizeAndPlayURI("spotify:track:20I6sIOMTCkB6w7ryavxtO")
                self.appRemote.connectionParameters.accessToken = self.token
                self.appRemote.delegate = self
                self.appRemote.connect()
            }
            
            
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.sessionManager.application(app, open: url, options: options)

        return true
    }
    
    var configuration = SPTConfiguration(
        clientID: "02294b5911c543599eb7fb37d1ed2d39",
        redirectURL: URL(string: "CranberryQueue://spotify-login-callback")!
    )
    
    var accessToken = String()
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        //appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        print("app remote instan")
        return appRemote
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "https://f.com/api/token"),
            let tokenRefreshURL = URL(string: "https://f.com/api/refresh_token") {
            self.configuration.tokenSwapURL = URL(string: "https://cranberryqueue.herokuapp.com/api/token")
            self.configuration.tokenRefreshURL = URL(string: "https://cranberryqueue.herokuapp.com/api/refresh_token")
            self.configuration.playURI = "spotify:track:20I6sIOMTCkB6w7ryavxtO"
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()

//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        let parameters = appRemote.authorizationParameters(from: url);
//
//        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
//            appRemote.connectionParameters.accessToken = access_token
//            self.accessToken = access_token
//            print(access_token)
//        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
//            print(error_description)
//        }
//        return true
//    }
    
//    func connect() {
//        self.appRemote.authorizeAndPlayURI("")
//        self.appRemote.playerAPI?.delegate = self
//        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
//            guard let res = result else {
//                print(error!)
//                return
//            }
//            print(res)
//        })
//    }

}

