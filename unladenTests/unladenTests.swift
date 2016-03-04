import XCTest
@testable import unladen

import Foundation
import RealmSwift

let WEB_PORT = UInt16(1999)
let UDP_PORT = UInt16(2112)
let SKT_PORT = UInt16(1382)
let TEST_SERVER_ADDRESS = "127.0.0.1"
let FOO = "foo"
let BAR = "bar"

// Realm models
class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
}

class Person: Object {
    dynamic var name = ""
    dynamic var picture: NSData? = nil
    let dogs = List<Dog>()
}

public class WebExample : WebServer {
    
    static let shared = WebExample()

    init() {
        super.init(port:WEB_PORT)
        self.get("/" + FOO, handler:foo)
        self.post("/" + BAR, handler:bar)
        
        realm()
    }
    
    // start the server, once, in the background thread
    static var webOnce : dispatch_once_t = 0
    override func serve() {
        dispatch_once(&WebExample.webOnce) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                self.serve()
            })
        }
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


public class UdpEchoServer : UdpServer {
    static let shared = UdpEchoServer(port: UDP_PORT)
    
    // start the server, once, in the background thread
    static var udpOnce : dispatch_once_t = 0
    override func serve() {
        dispatch_once(&UdpEchoServer.udpOnce) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                super.serve()
                print("serving");
            })
        }
    }
    
    override func processRequest(socket:Int32, data:[Int8], length:Int) -> NSData? {
        let str = String.fromCString(UnsafePointer(data))
        print("udp process request " + str!);
        xpector!.fulfill()
        print("processed!")
        return (str! + " yourself!").dataUsingEncoding(NSUTF8StringEncoding)
    }
}

public class SocketEchoServer : TcpServer {
    static let shared = SocketEchoServer(port: SKT_PORT)
    static var conn: Connection?

    // start the server, once, in the background thread
    static var sktOnce : dispatch_once_t = 0
    override func serve() {
        dispatch_once(&SocketEchoServer.sktOnce) {
            SocketEchoServer.conn = Connection(host: "127.0.0.1", port: SKT_PORT, callback: { data in
                let str = String.fromCString(UnsafePointer(data))
                print("socket process request " + str!);
                xpector!.fulfill()
                return nil
            })

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                super.serve()
                print("socket serving");
            })
        }
    }
    
    override func processRequest(socket:Int32, data:[Int8], length:Int) -> NSData? {
        let str = String.fromCString(UnsafePointer(data))
        print("socket server process request " + str!);
        return (str! + " yourself!").dataUsingEncoding(NSUTF8StringEncoding)
    }
}


public class UdpClient {


    class func htons(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8);
    }

    class func send(address:String, port:UInt16, message:String) {
        
        let INADDR_ANY = in_addr(s_addr: 0)

        var addr = sockaddr_in(
            sin_len:    __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port:   htons(port),
            sin_addr:   INADDR_ANY,
            sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
        )

        let fd = socket(AF_INET, SOCK_DGRAM, 0) // DGRAM makes it UDP
    
        message.withCString { cstr -> Void in
            withUnsafePointer(&addr) { ptr -> Void in
                let addrptr = UnsafePointer<sockaddr>(ptr)
                sendto(fd, cstr, Int(strlen(cstr)), 0,
                addrptr, socklen_t(addr.sin_len))
            }
        }
    }
}

var xpector: XCTestExpectation? = nil


// todo: make extensions to NSData
func string2data(string:String) -> NSData? {
    return string.dataUsingEncoding(NSUTF8StringEncoding)
}

class unladenTests: XCTestCase {

    override func setUp() {
        super.setUp()
        xpector = expectationWithDescription("longRunningFunction")
        WebExample.shared.serve()
        UdpEchoServer.shared.serve()
        SocketEchoServer.shared.serve()
        sleep(1)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func xtestRest() {
        
        let params = ["a":"1", "b":"2"]
        HttpClient.get(params, url:TEST_SERVER_ADDRESS + FOO, callback:{ status, response in
            XCTAssert(status == 200)
        })

        HttpClient.post(params, url:TEST_SERVER_ADDRESS+BAR, callback:{ status, response in
            XCTAssert(status == 200)
        })
        
        HttpClient.post(params, url:TEST_SERVER_ADDRESS+FOO+BAR, callback:{ status, response in
            XCTAssert(status == 404)
        })
    }

    
    func xtestUDP() {

        UdpClient.send(TEST_SERVER_ADDRESS, port: UDP_PORT, message: "echo")
        print("udp test done")
    }

    func testSocket() {
       
        SocketEchoServer.conn!.connect()
        SocketEchoServer.conn!.send(string2data("hi")!)

        self.waitForExpectationsWithTimeout(5) { error in
            print("wait error")
        }
}

    func xtestPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
