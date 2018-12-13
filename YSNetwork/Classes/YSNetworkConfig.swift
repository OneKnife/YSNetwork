//
//  HTNetworkConfig.swift
//  Hitour
//
//  Created by 赵一超 on 2018/8/6.
//  Copyright © 2018年 Veaer. All rights reserved.
//

import UIKit
import Alamofire

class YSNetworkConfig: NSObject {
    
    /// 请求超时时间
    func requestTimeoutInterval() -> TimeInterval {
        return 60
    }

    func baseUrl() -> String {
        return ""
    }
    
    /// request header fields
    func requsetHeaderFields() -> [String: String]?{
        return Alamofire.SessionManager.defaultHTTPHeaders
    }
    
    /// addition header fields
    func additionHeaderFields() -> [String: String]?{
        return nil
    }
    
    /// addition params
    func additionParams() -> [String: Any]?{
        return nil
    }

}
