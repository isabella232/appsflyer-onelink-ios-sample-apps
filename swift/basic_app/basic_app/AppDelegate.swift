//
//  AppDelegate.swift
//  basic_app
//
//  Created by Liaz Kamper on 11/05/2020.
//  Copyright © 2020 OneLink. All rights reserved.
//

import UIKit
import AppsFlyerLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1 - Get AppsFlyer preferences from .plist file
        guard let propertiesPath = Bundle.main.path(forResource: "afdevkey_donotpush", ofType: "plist"),
            let properties = NSDictionary(contentsOfFile: propertiesPath) as? [String:String] else {
                fatalError("Cannot find `afdevkey_donotpush`")
        }
        guard let appsFlyerDevKey = properties["appsFlyerDevKey"],
                   let appleAppID = properties["appleAppID"] else {
            fatalError("Cannot find `appsFlyerDevKey` or `appleAppID` key")
        }
        // 2 - Replace 'appsFlyerDevKey', `appleAppID` with your DevKey, Apple App ID
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = appleAppID
        //  Set isDebug to true to see AppsFlyer debug logs
        AppsFlyerLib.shared().isDebug = true
        
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        
        // 3 - Subscribe to didBecomeActiveNotification if you use SceneDelegate or just call
        // -[AppsFlyerTracker trackAppLaunch] from -[AppDelegate applicationDidBecomeActive:]
        NotificationCenter.default.addObserver(self,
        selector: #selector(didBecomeActiveNotification),
        // For Swift version < 4.2 replace name argument with the commented out code
        name: UIApplication.didBecomeActiveNotification, //.UIApplicationDidBecomeActive for Swift < 4.2
        object: nil)
        
        return true
    }
    
    @objc func didBecomeActiveNotification() {
        AppsFlyerLib.shared().start()
    }
    
    // Open Univerasal Links
    
    // For Swift version < 4.2 replace function signature with the commented out code
    // func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool { // this line for Swift < 4.2
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    // Open Deeplinks
    
    // Open URI-scheme for iOS 8 and below
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        return true
    }
    
    // Open URI-scheme for iOS 9 and above
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    // Report Push Notification attribution data for re-engagements
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }
    
    // User logic
    fileprivate func walkToSceneWithParams(deepLinkObj: DeepLink) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
        
       guard let fruitNameStr = deepLinkObj.clickEvent["deep_link_value"] as? String else {
            print("Could not extract query params from link")
            return
        }
               
        let destVC = fruitNameStr + "_vc"
        if let newVC = storyBoard.instantiateVC(withIdentifier: destVC) {
            
            print("AppsFlyer routing to section: \(destVC)")
            newVC.deepLinkData = deepLinkObj
            
             UIApplication.shared.windows.first?.rootViewController?.present(newVC, animated: true, completion: nil)
        } else {
            print("AppsFlyer: could not find section: \(destVC)")
        }
    }
}

extension AppDelegate: DeepLinkDelegate {
     
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            print("Deep link not found")
        case .found:
            let deepLinkStr:String = result.deepLink!.toString()
            print("DeepLink data is: \(deepLinkStr)")
            
            if( result.deepLink?.isDeferred == true) {
                print("This is a deferred deep link")
            } else {
                print("This is a direct deep link")
            }
            walkToSceneWithParams(deepLinkObj: result.deepLink!)
        case .failure:
            print("Error %@", result.error!)
        }
    }
    
}

extension AppDelegate: AppsFlyerLibDelegate {
     
    // Handle Organic/Non-organic installation
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        
        print("onConversionDataSuccess data:")
        for (key, value) in data {
            print(key, ":", value)
        }
        
        if let status = data["af_status"] as? String {
            if (status == "Non-organic") {
                if let sourceID = data["media_source"],
                    let campaign = data["campaign"] {
                    print("This is a Non-Organic install. Media source: \(sourceID)  Campaign: \(campaign)")
                }
            } else {
                print("This is an organic install.")
            }
            if let is_first_launch = data["is_first_launch"] as? Bool,
                is_first_launch {
                print("First Launch")
            } else {
                print("Not First Launch")
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        print("\(error)")
    }
}

extension UIStoryboard {
    func instantiateVC(withIdentifier identifier: String) -> DLViewController? {
        // "identifierToNibNameMap" – dont change it. It is a key for searching IDs
        if let identifiersList = self.value(forKey: "identifierToNibNameMap") as? [String: Any] {
            if identifiersList[identifier] != nil {
                return self.instantiateViewController(withIdentifier: identifier) as? DLViewController
            }
        }
        return nil
    }
}
