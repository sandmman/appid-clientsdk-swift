//
//  UserAttributeManagerImpl.swift
//  OdedAppIDdonotdeleteappid
//
//  Created by Moty Drimer on 21/02/2017.
//  Copyright © 2017 Oded Betzalel. All rights reserved.
//

import Foundation
import BMSCore

public class UserAttributeManagerImpl: UserAttributeManager {
    
    private var userProfileAttributesPath = "attributes"
    private(set) var appId:AppID
    
    init(appId:AppID) {
        self.appId = appId
    }
    
    public func setAttribute(key: String, value: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.PUT, key: key, value: value, accessTokenString: getLatestToken(), delegate: delegate);
    }
    public func setAttribute(key: String, value: String, accessTokenString: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.PUT, key: key, value: value, accessTokenString: accessTokenString, delegate: delegate);
    }
    
    public func getAttribute(key: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.GET, key: key, value: nil, accessTokenString: getLatestToken(), delegate: delegate);
    }
    public func getAttribute(key: String, accessTokenString: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.GET, key: key, value: nil, accessTokenString: accessTokenString, delegate: delegate);
    }
    
    public func deleteAttribute(key: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.DELETE, key: key, value: nil, accessTokenString: getLatestToken(), delegate: delegate);
    }
    public func deleteAttribute(key: String, accessTokenString: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.DELETE, key: key, value: nil, accessTokenString: accessTokenString, delegate: delegate);
    }
    
    public func getAttributes(delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.GET, key: nil, value: nil, accessTokenString: getLatestToken(), delegate: delegate);
    }
    public func getAttributes(accessTokenString: String, delegate: UserAttributeDelegate) {
        sendRequest(method: HttpMethod.GET, key: nil, value: nil, accessTokenString: accessTokenString, delegate: delegate);
    }
    
    
    internal func sendRequest(method: HttpMethod, key: String?, value: String?, accessTokenString: String?, delegate: UserAttributeDelegate) {
        var urlString = Config.getAttributesUrl(appId: appId) + userProfileAttributesPath;
        
        if (key != nil) {
            let unWrappedKey = key!;
            urlString = urlString + "/" + Utils.urlEncode(unWrappedKey);
        }
        
        let url = URL(string: urlString)
        var req = URLRequest(url: url!)
        req.httpMethod = method.rawValue
        req.timeoutInterval = BMSClient.sharedInstance.requestTimeout;
        
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if (accessTokenString != nil) {
            req.setValue("Bearer " + accessTokenString!, forHTTPHeaderField: "Authorization")
        }
        
        if (value != nil){
            let unwrappedValue = value!;
            req.httpBody=unwrappedValue.data(using: .utf8)
        }
        
        let urlSession = URLSession.shared
        
        let dataTask = urlSession.dataTask(with: req, completionHandler: {(data, response, error) in
            if response != nil {
                let unWrappedResponse = response as! HTTPURLResponse
                if unWrappedResponse.statusCode>=200 && unWrappedResponse.statusCode < 300 {
                    guard let unWrappedData = data else {
                        delegate.onFailure(error: UserAttributeError.userAttributeFailure("Failed to parse server response - no response text"))
                        return
                    }
                    var responseJson : [String:Any] = [:]
                    do {
                        let responseText = String(data: unWrappedData, encoding: .utf8)
                        if let unWrappedText = responseText {
                            if responseText != "" {
                                responseJson =  try Utils.parseJsonStringtoDictionary(unWrappedText)
                            }
                        }
                        
                    } catch (_) {
                        delegate.onFailure(error: UserAttributeError.userAttributeFailure("Failed to parse server response - failed to parse json"))
                        return
                    }
                    delegate.onSuccess(result: responseJson);
                }
                else {
                    if unWrappedResponse.statusCode == 401 {
                        delegate.onFailure(error: UserAttributeError.userAttributeFailure("UNATHORIZED"))
                    } else if unWrappedResponse.statusCode == 404 {
                        delegate.onFailure(error: UserAttributeError.userAttributeFailure("NOT FOUND"))
                    }
                    
                }
            } else {
                delegate.onFailure(error: UserAttributeError.userAttributeFailure("Failed to get response from server"))
                
            }
            
            
            
        })
        dataTask.resume()
    }
    
    private func getLatestToken() -> String? {
        return  appId.oauthManager?.tokenManager?.latestAccessToken?.raw
    }
}