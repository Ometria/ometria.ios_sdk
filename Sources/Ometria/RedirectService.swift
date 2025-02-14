//
//  RedirectService.swift
//  Ometria
//
//  Created by Cata on 6/23/21.
//

import Foundation

internal class RedirectService: NSObject, URLSessionTaskDelegate {
    
    var lastRedirectRequest: URLRequest?
    var callback: ((URL?, Error?) -> ())?
  
    private var didHandleCallback: Bool = false
    
    internal func getRedirect(url: URL, callback: @escaping (URL?, Error?) -> ()) {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        let headers = ["cache-control": "no-cache"]
        request.allHTTPHeaderFields = headers
        
        self.callback = callback
        
        getRedirect(request: request)
    }
    
    private func getRedirect(request: URLRequest) {
        let redirectSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        lastRedirectRequest = request
        
        let dataTask = redirectSession.dataTask(with: request) { [weak self] (data, response, error) in
            
            DispatchQueue.main.async {
                if let error = error {
                    if !(self?.didHandleCallback ?? true) {
                      self?.didHandleCallback = true
                      self?.callback?(nil, error)
                    }
                    return
                }
                if !(self?.didHandleCallback ?? true) {
                  self?.didHandleCallback = true
                  self?.callback?(self?.lastRedirectRequest?.url, nil)
                }
            }
        }
        
        dataTask.resume()
    }
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        DispatchQueue.main.async { [weak self] in
          if !(self?.didHandleCallback ?? true) {
            self?.didHandleCallback = true
            self?.callback?(request.url, nil)
          }
        }
        
        // Stop following redirects
        completionHandler(nil)
    }
}
