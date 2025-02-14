//
//  RedirectService.swift
//  Ometria
//
//  Created by Cata on 6/23/21.
//

import Foundation

internal class RedirectService: NSObject, URLSessionTaskDelegate {
    
    private var lastRedirectRequest: URLRequest?
    private var domain: String?
    private var regex: String?
    private var callback: ((URL?, Error?) -> ())?
    
    internal func getRedirect(url: URL, domain: String?, regex: String?, callback: @escaping (URL?, Error?) -> ()) {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        let headers = ["cache-control": "no-cache"]
        request.allHTTPHeaderFields = headers
        
        self.domain = domain
        self.regex = regex
        self.callback = callback
        
        getRedirect(request: request)
    }
    
    private func getRedirect(request: URLRequest) {
        let redirectSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        lastRedirectRequest = request
      
        if let lastUrl = lastRedirectRequest?.url {
            if let domain, urlBelongsToDomain(url: lastUrl, domain: domain) {
                callback?(lastUrl, nil)
                return
            }
            if let regex, lastUrl.absoluteString.range(of: regex, options: .regularExpression) != nil {
                callback?(lastUrl, nil)
                return
            }
        }
      
        let dataTask = redirectSession.dataTask(with: request) { [weak self] (data, response, error) in
            
            DispatchQueue.main.async {
                if let error = error {
                    self?.callback?(nil, error)
                    return
                }
                self?.callback?(self?.lastRedirectRequest?.url, nil)
            }
        }
        
        dataTask.resume()
    }
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        getRedirect(request: request)
    }
  
    private func urlBelongsToDomain(url: URL, domain: String) -> Bool {
        guard let host = url.host else { return false }
        return host == domain || host == "www.\(domain)"
    }
}
