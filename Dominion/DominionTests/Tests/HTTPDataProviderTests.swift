//
//  HTTPDataProviderTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest

@testable import Dominion

class HTTPDataProviderTests: XCTestCase {
        
    private var transport: FakeHTTPTransport!
    private var provider: HTTPDataProvider!
    
    override func setUp() {
        transport = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(5))
        provider = HTTPDataProvider(with: transport)
        provider.commonHeaders = ["common": "common"]
    }
    
    // 1. headers used
    
    func testHeaders() {
        
        let e = expectation(description: "Headers")
        
        transport.interceptor = { _, response, _ in
            if let r = response {
                XCTAssert(r.originalURLRequest?.allHTTPHeaderFields?["common"] == "common", "Common Header Not Found")
                XCTAssert(r.originalURLRequest?.allHTTPHeaderFields?["user"] == "user", "Configuration Header Not Found")
            }
            e.fulfill()
        }
        
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user, headers: ["user": "user"])
        
        transport.inject(configuration, data: userData, statusCode: 200)
        
        let task = provider.perform(using: configuration) { _ in }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 2. [200 - 299] with data: receiveData
    
    func testSuccessData() {
        let e = expectation(description: "Received Data")
                
        let configuration = URLRequestConfiguration<User, Error>(route: Routes.user)
        
        transport.inject(configuration, data: userData, statusCode: 200)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .value(let user):
                XCTAssert(user.name == "Gabriele", "Wrong Decoded Object")
            default:
                XCTAssert(false, "Expected Data Missing")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 3. [200 - 299] wrong data format: parse error
    
    func testSuccessWrongData() {
        let e = expectation(description: "Received Wrong Data")
                
        let configuration = URLRequestConfiguration<User, Error>(route: Routes.user)
        
        transport.inject(configuration, data: wrongData, statusCode: 200)
        
        let task = provider.perform(using: configuration) { result in
            switch result {
            case .failure(let error):
                XCTAssert(type(of: error) == DecodingError.self, "Should be a decoding error")
            case .success:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 4. [200 - 299] data - Empty transformer
    
    func testSuccessEmptyDataWantedRightData() {
        let e = expectation(description: "Received Data - Empty Transformer")
                
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user)
        
        transport.inject(configuration, data: userData, statusCode: 200)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .emptyValue:
                break
            default:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 5. [200 - 299] no data: empty
    
    func testSuccessEmptyDataNoData() {
        let e = expectation(description: "Null Data - Empty Transformer")
                
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user)
        
        transport.inject(configuration, data: nil, statusCode: 200)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .emptyValue:
                break
            default:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 6. error with data: receiveData
    
    func testErrorData() {
        let e = expectation(description: "Received Error Data")
                
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        transport.inject(configuration, data: apiErrorData, statusCode: 400)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .error(let error):
                XCTAssert((error as? ApiError)?.code == 1234, "ApiError Expected")
            default:
                XCTAssert(false, "Expected Data Missing")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 7. error with wrong data: parse error
    
    func testErrorWrongData() {
        let e = expectation(description: "Received Error Wrong Data")
                
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        transport.inject(configuration, data: wrongData, statusCode: 400)
        
        let task = provider.perform(using: configuration) { result in
            switch result {
            case .failure(let error):
                XCTAssert(type(of: error) == DecodingError.self, "Should be a decoding error")
            case .success:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 8. error data - Empty transformer
    
    func testErrorEmptyDataWantedRightData() {
        let e = expectation(description: "Received Error Data - Empty Transformer")
                
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user)
        
        transport.inject(configuration, data: userData, statusCode: 400)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .emptyError(let error):
                XCTAssert((error as? FakeHTTPTransportError) == .genericError, "Fake Generic Error Expected")
            default:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 9. error no data: empty
    
    func testErrorEmptyDataNoData() {
        let e = expectation(description: "Null Data - Empty Transformer")
                
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user)
        
        transport.inject(configuration, data: nil, statusCode: 400)
        
        let task = provider.perform(using: configuration) { result in
            switch result.response {
            case .emptyError(let error):
                XCTAssert((error as? FakeHTTPTransportError) == .genericError, "Fake Generic Error Expected")
            default:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    // 10. Error invalid response: error invalid response
    
    func testInvalidResponse() {
        let e = expectation(description: "Invalid Response")
                
        let configuration = URLRequestConfiguration<Void, Error>(route: Routes.user)
                
        let task = provider.perform(using: configuration) { result in
            switch result {
            case .failure(let error):
                XCTAssert((error as? HTTPDataProviderError) == .invalidResponse, "Fake Generic Error Expected")
            default:
                XCTAssert(false, "Unexpected data found")
                break
            }
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
}
