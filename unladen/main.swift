import Foundation

let PORT = 1999

class WebExample : WebServer {
    
    init() {
        super.init(port:PORT)
        self.get("/foo", handler:foo)
        self.post("/bar", handler:bar)
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
}

//let web = WebExample()
//web.serve()

class UdpExample : UdpServer {
    
    init() {
        super.init(port: PORT)
    }
}

let udp = UdpExample()
udp.serve()


