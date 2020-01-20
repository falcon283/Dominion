//
//  URLRequestConfigurationTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest

import Dominion

class URLRequestConfigurationTests: XCTestCase {
    
    private func checkDefaultValues<C: ResourceConfiguration>(for configuration: C) where C.Request == URLRequest {
        let request = configuration.request
        
        XCTAssert(request.httpMethod == "GET", "Default httpMethod must be GET")
        XCTAssert(request.allHTTPHeaderFields?.isEmpty == true, "Default headers must be empty")
        XCTAssert(request.cachePolicy == .returnCacheDataElseLoad, "Default cachePolicy must be returnCacheDataElseLoad")
        XCTAssert(request.timeoutInterval == 60.0, "Default timeout must be 60.0")
        
        switch configuration.expiration {
        case .never:
            break
        default:
            XCTAssert(false, "Default resource expiration must be never")
        }
    }
    
    // 1. Expiration
    
    func textExpiration() {
        
        let c1 = URLRequestConfiguration(route: Routes.user)
        
        switch c1.expiration {
        case .never:
            break
        default:
            XCTAssert(false, "Default resource expiration must be never")
        }

        let c2 = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        switch c2.expiration {
        case .interval(let time):
            XCTAssert(time == 60.0, "Wrong expiration interval")
        default:
            XCTAssert(false, "Expiration should be interval")
        }

        let expirationDate = Date()
        let c3 = URLRequestConfiguration(route: Routes.user, expiration: .date(expirationDate))

        switch c3.expiration {
        case .date(let date):
            XCTAssert(date == expirationDate, "Wrong expiration date")

        default:
            XCTAssert(false, "Default resource expiration must be date")
        }
    }
    
    // 2. Transform Object, Error
    
    func testObjectAndError() {
        
        let c = URLRequestConfiguration(route: Routes.user)
        checkDefaultValues(for: c)
        
        XCTAssertThrowsError(try c.transform(Data()), "Transform should throw") { error in
            switch error {
            case TransformerFailure.desiredEmpty:
                break
            default:
                XCTAssert(false, "desiredEmpty is expected")
            }
        }
        
        XCTAssertThrowsError(try c.transformError(Data()), "Transform Error should throw") { error in
            switch error {
            case TransformerFailure.desiredEmpty:
                break
            default:
                XCTAssert(false, "desiredEmpty is expected")
            }
        }
    }
    
    // 2bis. Transform Object, NSError
    
    func testObjectAndNSError() {
        
        let testError = NSError(domain: "Fake", code: 400, userInfo: nil)
        let errorTransformer = BlockTransformer<Data, NSError>(tranform: { _ in throw testError })
        let c = URLRequestConfiguration<Void, NSError>(route: Routes.user, error: errorTransformer)
        checkDefaultValues(for: c)
        
        XCTAssertThrowsError(try c.transform(Data()), "Transform should throw") { error in
            switch error {
            case TransformerFailure.desiredEmpty:
                break
            default:
                XCTAssert(false, "desiredEmpty is expected")
            }
        }
        
        XCTAssertThrowsError(try c.transformError(Data()), "transformError should throw") { error in
            XCTAssert((error as NSError) === testError, "Wrong Error")
        }
    }
    
    // 3. Transform Codable, Error
    
    func testCodableObjectAndError() {
        
        let c = URLRequestConfiguration<User, Error>(route: Routes.user)
        checkDefaultValues(for: c)
        
        
        XCTAssertNoThrow(try c.transform(userData), "Transform should not throw")
        
        XCTAssertThrowsError(try c.transformError(Data()), "Transform Error should throw") { error in
            switch error {
            case TransformerFailure.desiredEmpty:
                break
            default:
                XCTAssert(false, "desiredEmpty error is expected")
            }
        }
    }
    
    func testCodableObjectAndErrorWithUpstream() {
        
        let c = URLRequestConfiguration<User, Error>(route: Routes.user,
                                                     upstream: Upstream(with: EncodableTransformer(), using: "text"))
        checkDefaultValues(for: c)
        
        
        XCTAssertNoThrow(try c.transform(userData), "Transform should not throw")
        
        XCTAssertThrowsError(try c.transformError(Data()), "Transform Error should throw") { error in
            switch error {
            case TransformerFailure.desiredEmpty:
                break
            default:
                XCTAssert(false, "desiredEmpty error is expected")
            }
        }
    }
    
    // 4. Transform Codable, Codable Error
    
    func testCodableObjectAndCodableError() {
        
        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        checkDefaultValues(for: c)
        
        XCTAssertNoThrow(try c.transform(userData), "Transform should not throw")
        
        XCTAssertNoThrow(try c.transformError(apiErrorData), "Transform Error should not throw")
    }
    
    // 5. Upstream
    
    func testUpstreamGet() {
        
        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user,
                                                        upstream: Upstream(with: EncodableTransformer(), using: "text"))
        
        XCTAssert(c.request.httpBody == nil, "Body must be nil for Get requests")
    }
    
    func testUpstreamPost() {
        
        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user,
                                                        method: .post,
                                                        upstream: Upstream(with: EncodableTransformer(), using: "text"))
        
        let request = c.request
        
        if let data = request.httpBody {
            let text = try? JSONDecoder().decode(String.self, from: data)
            XCTAssert(text == "text", "Unexpected encoded object")
        } else {
            XCTAssert(false, "Expected Data in Body")
        }
    }
    
    func testUpstreamUsingErrorPostWithItem() {
        
        let c = URLRequestConfiguration<User, Error>(route: Routes.user,
                                                     method: .post,
                                                     body: "text")
        
        let request = c.request
        
        if let data = request.httpBody {
            let text = try? JSONDecoder().decode(String.self, from: data)
            XCTAssert(text == "text", "Unexpected encoded object")
        } else {
            XCTAssert(false, "Expected Data in Body")
        }
    }
    
    func testUpstreamUsingApiErrorPostWithItem() {
        
        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user,
                                                        method: .post,
                                                        body: "text")
        
        let request = c.request
        
        if let data = request.httpBody {
            let text = try? JSONDecoder().decode(String.self, from: data)
            XCTAssert(text == "text", "Unexpected encoded object")
        } else {
            XCTAssert(false, "Expected Data in Body")
        }
    }
    
    // 6. Aggressive
    
    func testAggressive() {
        
        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user).aggressiveConfiguration()
        
        let request = c.request
        
        XCTAssert(request.cachePolicy == .reloadIgnoringLocalCacheData, "Default cachePolicy must be reloadIgnoringLocalCacheData")
    }
}
