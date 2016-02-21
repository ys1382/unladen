import XCTest
@testable import unladen

import RealmSwift

let PORT = 1999


// Define your models like regular Swift classes
class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
}

class Person: Object {
    dynamic var name = ""
    dynamic var picture: NSData? = nil // optionals supported
    let dogs = List<Dog>()
}

class WebExample : WebServer {
    
    init() {
        super.init(port:PORT)
        self.get("/foo", handler:foo)
        self.post("/bar", handler:bar)
        
        realm()
    }
    
    func stringIfNil(d:[String:String]?) -> String {
        if d == nil {
            return "nil"
        } else {
            return d!.description
        }
    }
    
    func foo(requestParams:[String:String]?) -> NSData {
        let p = stringIfNil(requestParams)
        let response = "you requested foo(\(p))"
        return response.data()!
    }
    
    func bar(requestParams:[String:String]?) -> NSData {
        let p = stringIfNil(requestParams)
        return "you requested bar(\(p))".data()!
    }

    func realm() {
        
        // Use them like regular Swift objects
        let myDog = Dog()
        myDog.name = "Rex"
        myDog.age = 1
        printlog("name of dog: \(myDog.name)")
        
        // Get the default Realm
        let realm = try! Realm()
        
        // Query Realm for all dogs less than 2 years old
        let puppies = realm.objects(Dog).filter("age < 2")
        puppies.count // => 0 because no dogs have been added to the Realm yet
        
        // Persist your data easily
        try! realm.write {
            realm.add(myDog)
        }
        
        // Queries are updated in real-time
        puppies.count // => 1
        
        // Query and update from any thread
        dispatch_async(dispatch_queue_create("background", nil)) {
            let realm = try! Realm()
            let theDog = realm.objects(Dog).filter("age == 1").first
            try! realm.write {
                theDog!.age = 3
            }
        }
    }
}


class unladenTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    
        var token: dispatch_once_t = 0
        func test() {
            dispatch_once(&token) {
                let web = WebExample()
                web.serve()
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
