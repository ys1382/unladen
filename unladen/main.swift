import Foundation

class Example : WebServer {
    
    override init() {
        super.init()
        self.get("/foo", handler:foo)
        self.post("/bar", handler:bar)
    }
    
    func foo(requestParams:[String:String]?) -> String {
        return "you requested foo(\(requestParams))"
    }
    
    func bar(requestParams:[String:String]?) -> String {
        return "you requested bar(\(requestParams))"
    }
}

let example = Example()
example.serveOnPort(1999)