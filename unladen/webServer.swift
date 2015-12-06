import Foundation

class WebServer : TcpServer {

    typealias Handler = ([String:String]?) -> (String)
    var routes = [String:[String:Handler]]()
    static let GET = "GET"
    static let POST = "POST"
    
    func get(route:String, handler:Handler) {
        self.setRoute(WebServer.GET, route:route, handler:handler)
    }

    func post(route:String, handler:Handler) {
        self.setRoute(WebServer.POST, route:route, handler:handler)
    }
    
    override init() {
        self.routes[WebServer.GET] = [String:Handler]()
        self.routes[WebServer.POST] = [String:Handler]()
    }
    
    func setRoute(method:String, route:String, handler:Handler) {
        self.routes[method]![route] = handler
    }

    func dictify(params:String) -> [String:String] {
        var response = [String:String]()
        for p in params.componentsSeparatedByString("&") {
            let kv = p.componentsSeparatedByString("=")
            response[kv[0]] = kv[1]
        }
        return response
    }
    
    func parseParams(method:String, request:String) -> [String:String]? {
        switch method {

            case WebServer.GET:
                if let q = request.rangeOfString("?")?.startIndex.advancedBy(1) {
                    let r = request.substringFromIndex(q    )
                    let s = r.componentsSeparatedByString(" ")[0]
                    return dictify(s)
                }
            
            case WebServer.POST:
                let q = request.rangeOfString("\n", options:NSStringCompareOptions.BackwardsSearch)?.startIndex.advancedBy(1)
                let r = request.substringFromIndex(q!)
                return dictify(r)
            
            default:
                print("method \(method) not supported")
        }
        return nil
    }

    override func processRequest(socket:Int32, data:[Int8], length:Int) {
        let request = NSString(bytes: data, length:length, encoding: NSUTF8StringEncoding)
        let response = handleRoute(request! as String)
        let array: [UInt8] = Array(response.utf8)
        send(socket, array, array.count, 0)
        close(socket)
    }

    func handleRoute(request:String) -> String {
        let separators = NSCharacterSet(charactersInString: " ,?")
        let components = request.componentsSeparatedByCharactersInSet(separators)
        let method = components[0]
        let route = components[1]
        let params = parseParams(method, request:request)
        var response = ""
        if let handler = self.routes[method]![route] {
            response = handler(params)
        }
        return "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: \(response.characters.count)\r\n\r\n\(response)"
    }
}