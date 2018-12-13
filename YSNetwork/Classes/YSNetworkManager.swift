//
//  YSNetworkManager.swift
//  Hitour
//
//  Created by 赵一超 on 2018/8/6.
//  Copyright © 2018年 Veaer. All rights reserved.
//

import UIKit
import Alamofire

class YSNetworkManager: NSObject {
    static let shareInstance = YSNetworkManager()
    var manager = Alamofire.SessionManager.default
    var requestRecord: [Int: YSBaseRequest] = [:]
    var config: YSNetworkConfig?
    let lock = NSLock()
    
    //MARK: - Setup
    private override init() {
//        manager.startRequestsImmediately = false
    }
    func setup(config: YSNetworkConfig) {
        self.config = config
        
        let sessionConfig = Alamofire.SessionManager.default.session.configuration
        // set request time out
        sessionConfig.timeoutIntervalForRequest = config.requestTimeoutInterval()
        manager = Alamofire.SessionManager(configuration: sessionConfig)
    }
    
    //MARK: - build request
    /// add request and start
    func addRequest(request: YSBaseRequest) {
        request.afrequest = self.addRequestFrom(request: request)
        switch request.requestPriority {
        case .low:
            request.requestTask?.priority = URLSessionTask.lowPriority
        case .normal:
            request.requestTask?.priority = URLSessionTask.defaultPriority
        case .high:
            request.requestTask?.priority = URLSessionTask.highPriority
        }
//        request.afrequest?.resume()
        request.delegate?.requestStart(request: request)
    }
    
    /// cancel request
    func cancelRequest(request: YSBaseRequest) {
        request.afrequest?.cancel()
        self.removeRequestRecord(request: request)
    }
    
    /// cancel all added request
    func cancelAllRequest() {
        let copiedKeys = Array(requestRecord.keys)
        for key in copiedKeys {
            let request = requestRecord[key]
            request?.cancel()
        }
    }
    
    /// constructed URL of request
    func buildRequestUrl(request: YSBaseRequest) -> String {
        let detailUrl = request.requestUrl()
        let temp = URL.init(string: detailUrl)
        
        // temp is valid url
        if temp != nil && temp?.host != nil && temp?.scheme != nil {
            return detailUrl
        }
        
        let defaultBaseUrl = config?.baseUrl() ?? ""
        let baseUrl = request.baseUrl() ?? defaultBaseUrl
        guard var url = URL.init(string: baseUrl) else { return "" }
        if baseUrl.count > 0 && !baseUrl.hasSuffix("/") {
            url = url.appendingPathComponent("")
        }
        guard let urlStr = URL.init(string: detailUrl, relativeTo: url)?.absoluteString else { return "" }
        return urlStr
    }
    
    private func addRequestFrom(request: YSBaseRequest) -> Request? {
        
        let method = request.requestMethod()
        switch method {
        case .get:
            return self.addRequest(httpMethod: .get, request: request)
        case .post:
            return self.addRequest(httpMethod: .post, request: request)
        case .head:
            return self.addRequest(httpMethod: .head, request: request)
        case .put:
            return self.addRequest(httpMethod: .put, request: request)
        case .patch:
            return self.addRequest(httpMethod: .patch, request: request)
        case .delete:
            return self.addRequest(httpMethod: .delete, request: request)
        }
    }
    
    func addRequest(httpMethod: HTTPMethod, request: YSBaseRequest) -> Request?{
        
        guard let config = config else { debugPrint("[network]: setup with config first"); return nil }
        
        let url = self.buildRequestUrl(request: request)
        
        // build params
        var params = config.additionParams() ?? [:]
        for param in request.params ?? [:] {
            params[param.key] = param.value
        }
        
        // add addition headers
        var httpHeaders = config.requsetHeaderFields() ?? [:]
        if let requestHeader = request.requsetHeaderFields() {
            httpHeaders = requestHeader
        }
        let defaultAdditonHeaders = config.additionHeaderFields()
        let requestAdditonHeaders = request.additionHeaderFields()
        httpHeaders = self.addAdditonHeaders(originHeaders: httpHeaders, additonHeaders: defaultAdditonHeaders)
        httpHeaders = self.addAdditonHeaders(originHeaders: httpHeaders, additonHeaders: requestAdditonHeaders)
        
        guard var urlRequest = getURLRequest(url, method: httpMethod, parameters: params, encoding: URLEncoding.default, headers: httpHeaders) else {
            debugPrint("[network]: build urlRequest error")
            return nil
        }
        if let timeout = request.requestTimeoutInterval() {
            urlRequest.timeoutInterval = timeout
        }
        
        let afrequest = manager.request(urlRequest)
        afrequest.responseData {[weak self] (response) in
            self?.handleDataRequestResult(request: request, response: response)
        }

        return afrequest
    }
    
    /// build URLRequest
    private func getURLRequest(_ url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = Alamofire.URLEncoding.default, headers: HTTPHeaders? = nil) -> URLRequest? {
        var originalRequest: URLRequest?
        do {
            originalRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(originalRequest!, with: parameters)
            return encodedURLRequest
        } catch {
            debugPrint("[network]: \(error.localizedDescription)")
            return originalRequest
        }
    }
    
    /// add addition http headers
    private func addAdditonHeaders(originHeaders: [String: String], additonHeaders: [String: String]?) -> [String: String]{
        var newHeaders = originHeaders
        if let headers = additonHeaders {
            for (headerKey, value) in headers {
                newHeaders[headerKey] = value
            }
        }
        return newHeaders
    }
    
    func addRequestToRecord(request: YSBaseRequest) {
        lock.lock()
        defer { lock.unlock() }
        guard let identifier = request.requestTask?.taskIdentifier else { debugPrint("request identity invalid"); return }
        requestRecord[identifier] = request
    }
    
    func removeRequestRecord(request: YSBaseRequest) {
        lock.lock()
        defer { lock.unlock() }
        guard let identifier = request.requestTask?.taskIdentifier else { debugPrint("request identity invalid"); return }
        requestRecord[identifier] = nil
    }
    
    //MARK: - request delegate
    func handleDataRequestResult(request: YSBaseRequest, response: DataResponse<Data>) {
        debugPrint(request.afrequest)
        
        if response.result.error == nil {
            request.responseData = response.result.value
            request.responseObject = response.result.value
            if request.responseSerializerType() == .json {
                if let data = response.result.value {
                    do {
                        request.responseJSONObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                        request.requestDidSuccess()
                    }catch {
                        debugPrint("json serialization failed!")
                        request.requestDidFail()
                    }
                }
            }else {
                request.requestDidSuccess()
            }
            
        }else{
            request.requestDidFail()
        }
        DispatchQueue.main.async {
            self.removeRequestRecord(request: request)
        }
    }
    
    
    
}
