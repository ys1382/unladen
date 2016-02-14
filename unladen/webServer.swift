import Foundation

extension String {
    func data() -> NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding)
    }
}

class WebServer : TcpServer {

    typealias Handler = ([String:String]?) -> (NSData)
    var routes = [String:[String:Handler]]()
    var directory:String
    static let GET = "GET"
    static let POST = "POST"

    func get(route:String, handler:Handler) {
        self.setRoute(WebServer.GET, route:route, handler:handler)
    }

    func post(route:String, handler:Handler) {
        self.setRoute(WebServer.POST, route:route, handler:handler)
    }

    init(port:Int, directory:String=".") {
        self.directory = directory
        super.init(port:port)
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
                    let r = request.substringFromIndex(q)
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
        send(socket, response.bytes, response.length, 0)
        close(socket)
    }

    func handleRoute(request:String) -> NSData {
        let separators = NSCharacterSet(charactersInString: " ,?")
        let components = request.componentsSeparatedByCharactersInSet(separators)
        let method = components[0]
        var route = components[1]
        let params = parseParams(method, request:request)
        var response = "".data()

        if let handler = self.routes[method]![route] {
            response = handler(params)
        } else if method == WebServer.GET {
            let ri = route.startIndex.advancedBy(1)
            route = route.substringFromIndex(ri)
            response = NSData(contentsOfFile:route)
            if response == nil {
                let message = "404 -- can't find file \(route)".data()!
                return httpResponse(404, body: message)
            } else {
            }
        }
        return httpResponse(200, body:response!)
    }

    func printFirstBytes(body:NSData) {
        let count = body.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        body.getBytes(&array, length:count * sizeof(UInt8))
        for i in 0...3 {
            print("\(i): \(Int(array[i]))")
        }
    }

    func httpResponse(status:Int, body:NSData) -> NSData {
        let type = "\r\nContent-Type: text/html; charset=UTF-8"
        let length = "\r\nContent-Length: \(body.length)\r\n\r\n"
        let ok = status == 200 ? "OK" : ""
        let response = NSMutableData(data: "HTTP/1.1 \(status) \(ok)\(type)\(length)".data()!)
        response.appendData(body)
        return response
    }
}