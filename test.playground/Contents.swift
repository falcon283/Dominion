import UIKit


final class Func<A, B> {
    let op: (A) -> B
    
    init(_ function: @escaping (A) -> B) {
        self.op = function
    }
    
    func apply(_ a: A) -> B {
        self.op(a)
    }
    
    
}

extension Func {
    
    func map<C>(_ transform: @escaping (B) -> C) -> Func<A, C> {
//        return { a in transform(self.op(a)) }
        
        Func<A, C>.init { (a) -> C in
            transform(self.apply(a))
        }
    }
    
    func flatMap<C>(_ transform: @escaping (B) -> Func<A, C>) -> Func<A, C> {
    //        return { a in transform(self.op(a)) }
            
            Func<A, C>.init { (a) -> C in
                transform(self.apply(a)).apply(a)
            }
        }
    
    func lazy() -> Func<A, () -> B> {
        
        .init { (a) -> () -> B in
            return {
                self.apply(a)
            }
        }
    }
    
    func chain<C>(_ f: Func<B, C>) -> Func<A, C> {
        .init { (a) -> C in
            f.apply(self.apply(a))
        }
    }
    
    func dispatch(in queue: DispatchQueue) -> Func<A, (@escaping (B) -> Void) -> ()> {
        .init { (a) -> (@escaping (B) -> Void) -> () in
            { callback in
                queue.async {
                    callback(self.apply(a))
                }
            }
        }
    }
}

extension Func {
    
    func contraMap<C>(_ transform: @escaping (C) -> A) -> Func<C, B> {
        
        Func<C, B>.init { (c) -> B in
            self.apply(transform(c))
        }
    }
}


func increment(_ v: Int) -> Int {
    v+1
}

let inc = Func(increment)
let square: Func<Int, Int> = .init { $0 * $0 }

inc.chain(square).apply(10)

let notNow = inc.lazy().apply(2)


sleep(3)

notNow()

import XCTest

XCTAssertEqual(inc.map(String.init).map(Double.init).apply(1), inc.map { Double(String.init($0)) }.apply(1))



//struct User {
//    let id: Int
//    let name: String
//}
//
//let u = User(id: 1, name: "Gabriele")
//
//let c = inc.contraMap { (u: User) -> Int in
//    u.id
//}
////    .apply(u)
//
//c
