//
//  YSCacheRequest.swift
//  Hitour
//
//  Created by 赵一超 on 2018/8/9.
//  Copyright © 2018年 Veaer. All rights reserved.
//

import UIKit

/// 缓存文件信息 ( 日期，版本，编码格式等.. )
class YSCacheMetadata: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    var version: Int64?
    var sensitiveDataString: String?
    var stringEncoding: String.Encoding?
    var creationDate: Date?
    var appVersionString: String?

    override init() {
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.version, forKey: "version")
        aCoder.encode(self.sensitiveDataString, forKey: "sensitiveDataString")
        aCoder.encode(self.stringEncoding, forKey: "stringEncoding")
        aCoder.encode(self.creationDate, forKey: "creationDate")
        aCoder.encode(self.appVersionString, forKey: "appVersionString")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.version = aDecoder.decodeObject(forKey: "version") as? Int64
        self.sensitiveDataString = aDecoder.decodeObject(forKey: "sensitiveDataString") as? String
        self.stringEncoding = aDecoder.decodeObject(forKey: "stringEncoding") as? String.Encoding
        self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as? Date
        self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as? String
    }
}

class YSCacheRequest: YSBaseRequest {
    
    var cacheMetadata: YSCacheMetadata?
    var cacheData: Data?
    var cacheString: String?
    var cacheJSON: Any?
    
    let cacheWritingQueue: DispatchQueue = DispatchQueue.init(label: "htnetwork.cache.writing.queue")

    /// whether to use cache as response
    /// you should return cacheTime to take effect
    public var ignoreCache: Bool = false
    
    /// whether data is from storange
    var isDataFromCache: Bool = false
    
    /// whether load cache first then request new data again
    public var loadCacheAndRequestNewData: Bool = false
    
//    var  needCacheAndRequest
    
    /// whether return previous data if error
    func loadCacheIfValid() -> Bool{
        // cache time invalid
        if cacheTime() < 0 {
            return false
        }
        
        // 读取缓存文件信息
        if !self.loadCacheMetadata() {
            return false
        }
        
        // 检查缓存文件可用性
        if !self.cacheDataValidate() {
            return false
        }
        
        // 加载缓存数据
        if !loadCacheData() {
            return false
        }
        return true
    }
    
    /// request without cache
    public func requestWithoutCache(){
        super.request()
    }
    
    /// cache time of second
    public func cacheTime() -> Double {
        return -1
    }
    
    /// whether cache is asynchronously written to storage, default is true
    func writeCacheAsynchronously() -> Bool {
        return true
    }
    
    func cacheVersion() -> Int64 {
        return 0
    }
    
    override func request() {
        if self.ignoreCache {
            self.requestWithoutCache()
            return
        }
        
        if self.resumableDownloadPath != nil{
            self.requestWithoutCache()
            return
        }
        
        if !loadCacheIfValid() {
            self.requestWithoutCache()
            return
        }
        
        executeSuccessCallBack(isFromCache: true)
    }
    
    override var responseObject: Any?{
        get {
            if isDataFromCache {
                return cacheJSON
            }
            return super.responseObject
        }
        set {
            super.responseObject = newValue
        }
    }
    
    override var responseData: Data? {
        get {
            if isDataFromCache {
                return cacheData
            }
            return super.responseData
        }
        set {
            super.responseData = newValue
        }
    }
    
    override var responseString: String?{
        get {
            if isDataFromCache {
                return cacheString
            }
            return super.responseString
        }
        set {
            super.responseString = newValue
        }
    }
    
    override var responseJSONObject: Any? {
        get {
            if isDataFromCache {
                return cacheJSON
            }
            return super.responseJSONObject
        }
        set {
            super.responseJSONObject = newValue
        }
    }
    
    override func requestSuccessPreprocessor() {
        super.requestSuccessPreprocessor()
        if self.writeCacheAsynchronously() {
            cacheWritingQueue.async {
                self.saveResponseDataToCacheFile(data: super.responseData)
            }
        }else {
            saveResponseDataToCacheFile(data: super.responseData)
        }
    }
    
    //MARK: - private function
    
    /// check cache validate
    private func cacheDataValidate() -> Bool {
        guard let createDate = self.cacheMetadata?.creationDate else { return false }
        let duration = -createDate.timeIntervalSinceNow
        if duration < 0 || duration > self.cacheTime() {
            debugPrint("[network]: cache expired")
            return false
        }
        
//        let sensitiveDataString = self.cacheMetadata?.sensitiveDataString
//        let currentSensitiveDataString = self.cache
        
        let appversion = self.cacheMetadata?.appVersionString
        let currentAppVersion = YSNetworkUtils.applicationVersion()
        if appversion != currentAppVersion {
            debugPrint("[network]: appversion mismatch")
            return false
        }
        return true
    }
    
    /// 读取缓存文件信息
    private func loadCacheMetadata() -> Bool {
        let path = self.cacheMetadataFilePath()
        if FileManager.default.fileExists(atPath: path) {
            cacheMetadata = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? YSCacheMetadata
            if cacheMetadata != nil{
                return true
            }
        }
        return false
    }
    
    /// 加载缓存数据
    private func loadCacheData() -> Bool {
        let path = self.cacheFilePath()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            let url = URL.init(fileURLWithPath: path)
            do {
                let data = try Data.init(contentsOf: url)
                cacheData = data
                let cacheString = String.init(data: data, encoding: self.cacheMetadata?.stringEncoding ?? String.Encoding.ascii)
                self.cacheString = cacheString
                if self.responseSerializerType() == .json {
                    self.cacheJSON = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                }
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    /// 保存缓存数据到本地
    private func saveResponseDataToCacheFile(data: Data?) {
        if self.cacheTime() > 0 && !self.isDataFromCache {
            if data != nil {
                do {
                    let url = URL.init(fileURLWithPath: self.cacheFilePath())
                    try data?.write(to: url)
                    let metadata = YSCacheMetadata()
                    metadata.version = self.cacheVersion()
//                    metadata.sensitiveDataString = self.
                    metadata.creationDate = Date()
                    metadata.appVersionString = YSNetworkUtils.applicationVersion()
                    NSKeyedArchiver.archiveRootObject(metadata, toFile: self.cacheMetadataFilePath())
                } catch {
                    debugPrint("[network]: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 缓存文件基础路径
    func cacheBasePath() -> String {
        let pathOfCache = YSNetworkUtils.applicationCacheDirectory()
        let path = pathOfCache.appending("YSRequestCache")
        YSNetworkUtils.createFolderIfNeed(path: path)
        return path
    }
    
    /// 缓存文件名
    func cacheFileName() -> String{
        let requestUrl = self.requestUrl()
        let baseUrl = self.baseUrl() ?? YSNetworkManager.shareInstance.config?.baseUrl() ?? ""
        let argument = self.requestParams()
        let requestInfo = String.init(format: "Method: %d Host: %@ Url: %@ Argument: %@", requestMethod().rawValue, baseUrl, requestUrl, argument ?? "")
        let cacheFileName = YSNetworkUtils.getMD5(string: requestInfo)
        
        return cacheFileName
    }
    
    /// 缓存数据文件路径
    func cacheFilePath() -> String {
        let cacheFileName = self.cacheFileName()
        var path = self.cacheBasePath()
        path = (path as NSString).appendingPathComponent(cacheFileName)
        return path
    }
    
    /// 缓存信息文件路径
    func cacheMetadataFilePath() -> String {
        let cacheMetadataFileName = "\(self.cacheFileName()).metadata"
        var path = self.cacheBasePath()
        path = (path as NSString).appendingPathComponent(cacheMetadataFileName)
        return path
    }
    
    override func requestDidSuccess() {
        executeSuccessCallBack(isFromCache: false)
    }
    
    func executeSuccessCallBack(isFromCache: Bool) {
        self.isDataFromCache = isFromCache
        self.requestSuccessPreprocessor()
        
        if isDataFromCache == false && responseData == cacheData{
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.requestSucceed(request: self)
            self.successCallBack?(self)
            
            // request again
            if self.loadCacheAndRequestNewData && self.isDataFromCache {
                self.requestWithoutCache()
            }else{
                self.clearComplateBlock()
            }
        }
    }
    
    override func requestDidFail() {
        self.requestFailedPreprocessor()
        
        DispatchQueue.main.async {
            if self.delegate != nil {
                self.delegate?.requestFailed(request: self)
            }
            self.failureCallBack?(self)
        }
    }
    
    
    
    
    
    
    
}
