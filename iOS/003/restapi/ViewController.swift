//
//  ViewController.swift
//  restapi
//
//  Created by Junho HA on 2018. 10. 15..
//  Copyright © 2018년 hajunho.com. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    let urlString: String = "https://yoursite.com"
    let token: String = "/yourTokenAPI"
    let login: String = "/yourLoginAPI"
    let testUserName: String = "hajunho"
    let testPassword: String = "sorasorapululunsora"
    let json1level = "data"
    let json2level = "token"
    
    var count: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getLoginToken()
    }
    
    func connectionTest(_ site: String, auth: Bool) {
        Alamofire.request(site)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData { response in
                switch response.result {
                case .success:
                    print("Validation Successful \(self.count)")
                case .failure(let error):
                    if(auth) {
                        print("Authentication is needed for Validation ", self.count)
                    }
                    else {
                        assertionFailure()
                        print("Valication is Failed.", self.count, error)
                    }
                }
        }
    }
    
    func getLoginToken() {
        let parameters: Parameters = ["username": testUserName,
                                      "password": testPassword]
        
        connectionTest(urlString+login, auth: true)
        
        Alamofire.request(urlString+token, parameters: parameters).responseJSON { response in
            if(false) {
                print("Request: \(String(describing: response.request))")   // original url request
                print("Response: \(String(describing: response.response))") // http url response
                print("Result: \(response.result)")                         // response serialization result
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                }
            }
            
            if let json = response.result.value {
                if(false) {
                    print("JSON: \(json)") // serialized json response
                }
                
                let swiftyJsonVar = JSON(json)
                let resToken = swiftyJsonVar[self.json1level][self.json2level].stringValue //KEYPOINT!!
                print(resToken)
                
            }
        }
    }
}


