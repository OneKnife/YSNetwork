//
//  HTNetworkUtils.swift
//  Hitour
//
//  Created by 赵一超 on 2018/8/8.
//  Copyright © 2018年 Veaer. All rights reserved.
//

import UIKit

class YSNetworkUtils: NSObject {
    class func validateJSON(json: Any, jsonValidator: Any) {
        // TODO:
    }
    
    class func applicationVersion() -> String{
        if let ver = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String{
            return ver
        }
        return ""
    }
    
    class func applicationCacheDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! as String
    }

    class func getMD5(string: String) -> String {
        let cStr = string.cString(using: String.Encoding.utf8);
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
        let md5String = NSMutableString();
        for i in 0 ..< 16{
            md5String.appendFormat("%02x", buffer[i])
        }
        free(buffer)
        return md5String as String
    }

}
