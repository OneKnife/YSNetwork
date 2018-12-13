//
//  YSBaseRequest.swift
//  Hitour
//
//  Created by 赵一超 on 2018/8/2.
//  Copyright © 2018年 Veaer. All rights reserved.
//

import UIKit
import Alamofire

/// 错误类型
enum YSRequestValidationErrorType: Int {
    case invalidStatusCode = -1
    case invalidJSONFormat = -2
}

/// 请求类型
enum YSRequestMethod: Int {
    case get
    case post
    case head
    case put
    case patch
    case delete
}

/// response 类型
enum YSResponseSerializerType {
    case http
    case json
}

/// 请求优先级
enum YSRequestPriority {
    case low
    case normal
    case high
}

/// 网络请求回调
protocol YSRequestDelegate: NSObjectProtocol {
    func requestStart(request: YSBaseRequest)
    func requestSucceed(request: YSBaseRequest)
    func requestFailed(request: YSBaseRequest)
}

/// 辅助视图代理 (主要用于loadingView 等)
protocol YSRequestAccessoryDelegate {
    func requestStart(request: YSBaseRequest)
    func requestStop(request: YSBaseRequest)
}

typealias YSRequestCompleteBlock = (_ request: YSBaseRequest) -> Void
typealias YSURLSessionTaskProgressBlock = (_ progress: Progress) -> Void


class YSBaseRequest: NSObject {
    
    /// request params
    var params: [String: Any]?
    
    override init() {
    }
    
    init(params: [String: Any]) {
        self.params = params
    }
    
    //MARK - 请求信息
    var afrequest: Request?
    ///  Shortcut for `afrequest.task`
    var requestTask: URLSessionTask?{
        return afrequest?.task
    }
    
//    ///  Shortcut for `requestTask.currentRequest`
//    var currentRequest: URLRequest?{
//        return requestTask?.currentRequest
//    }
//    ///  Shortcut for `requestTask.originalRequest`.
//    var originalRequest: URLRequest?{
//        return requestTask?.originalRequest
//    }
    ///  Shortcut for `requestTask.response`.
    var response: YSTPURLResponse?{
        return afrequest?.response
    }
    /// response status code
    var responseStatusCode: Int?{
        return response?.statusCode
    }
    /// response header fields
    var responseHeaders: [AnyHashable: Any]?{
        return response?.allHeaderFields
    }
    /// data of response
    var responseData: Data?
    /// string of response
    var responseString: String?
    /// object of response
    var responseObject: Any?
    /// json object of response
    var responseJSONObject: Any?
    /// error of request
    var error: Error?
    /// the request canceled status
    var isCanceled: Bool {
        if requestTask == nil {
            return false
        }
        return requestTask?.state == .canceling
    }
    /// the request executing status
    var isExecuting: Bool {
        if self.requestTask == nil {
            return false
        }
        return self.requestTask?.state == .running
    }

    //MARK: - request configuration
    /// is used to identity request
    var tag: Int = 0
    /// addition info about the request
    var userInfo: [String: AnyObject]?
    /// delegate of the request
    weak var delegate: YSRequestDelegate?
    /// success callback
    var successCallBack: YSRequestCompleteBlock?
    /// fail callback
    var failureCallBack: YSRequestCompleteBlock?
//    var requestAccessories: []
    /// path to download file
    var resumableDownloadPath: String?
    /// progress of download file
    var resumableDownloadProgressBlock: YSURLSessionTaskProgressBlock?
    /// set request priority
    var requestPriority: YSRequestPriority = .normal
    /// set complate callback
    func setComplateBlock(success: YSRequestCompleteBlock?, failure: YSRequestCompleteBlock?){
        self.successCallBack = success
        self.failureCallBack = failure
    }
    /// set success & filure callback to nil
    func clearComplateBlock(){
        self.successCallBack = nil
        self.failureCallBack = nil
    }
    /// add request accessory
//    func addAccessory(<#parameters#>) -> <#return type#> {
//        <#function body#>
//    }
    
    //MARK: - request action
    ///  start request
    func request() {
        YSNetworkManager.shareInstance.addRequest(request: self)
    }
    /// cancel request
    func cancel() {
        YSNetworkManager.shareInstance.cancelRequest(request: self)
        self.clearComplateBlock()
    }
    
    /// start request & set complete callback
    func request(success successBlock: YSRequestCompleteBlock?,failed failureBlock: YSRequestCompleteBlock?) {
        self.successCallBack = successBlock
        self.failureCallBack = failureBlock
        request()
    }
    
    /// preprocess before complete callback
    func requestSuccessPreprocessor() {
    }
    
    /// preprocess before request failed callback
    func requestFailedPreprocessor() {
    }
    
    /// URL of server, if nil use network config baseUrl
    public func baseUrl() -> String?{
        return nil
    }
    
    /// URL of request route
    public func requestUrl() -> String{
        return ""
    }
    
    /// request timeout interval, defalut setting in NetworkConfig
    public func requestTimeoutInterval() -> TimeInterval? {
        return nil
    }
    
    /// request params
    public func requestParams() -> [String: Any]? {
        return params
    }
    
    /// request method
    public func requestMethod() -> YSRequestMethod {
        return .get
    }
    
    /// response serializer type
    public func responseSerializerType() -> YSResponseSerializerType {
        return .json
    }
    
    /// request header fields
    public func requsetHeaderFields() -> [String: String]?{
        return nil
    }
    
    /// addition header fields
    public func additionHeaderFields() -> [String: String]?{
        return nil
    }
    
    /// checkout json data
    func jsonValidator() -> Any?{
        return nil
    }
    
    /// checkout status code
    func statusCodeValidator() -> Bool{
        let statusCode = responseStatusCode ?? -1
        return statusCode >= 200 && statusCode <= 299
    }
    
    internal func requestDidSuccess() {
        self.requestSuccessPreprocessor()
        dispatch_async_on_main_queue {
            if self.delegate != nil {
                self.delegate?.requestSucceed(request: self)
            }
            self.successCallBack?(self)
        }
    }
    
    internal func requestDidFail() {
        self.requestFailedPreprocessor()
        
        dispatch_async_on_main_queue {
            if self.delegate != nil {
                self.delegate?.requestFailed(request: self)
            }
            self.failureCallBack?(self)
        }
    }
}

