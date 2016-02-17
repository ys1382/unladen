// based on http://swiftrien.blogspot.com/2015/10/socket-programming-in-swift-part-1.html

import Foundation

enum TransportLayer { case UDP, TCP }

class IpServer {

    let maxNumberOfConnectionsBeforeAccept = Int32(1000)
    let condition = NSCondition()
    var port:Int
    var layer:TransportLayer

    /// Replacement for FD_ZERO macro

    func fdZero(inout set: fd_set) {
        set.fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    /// Replacement for FD_SET macro

    func fdSet(fd: Int32, inout set: fd_set) {
        let intOffset = Int(fd / 32)
        let bitOffset = fd % 32
        let mask = 1 << bitOffset
        switch intOffset {
        case 0: set.fds_bits.0 = set.fds_bits.0 | mask
        case 1: set.fds_bits.1 = set.fds_bits.1 | mask
        case 2: set.fds_bits.2 = set.fds_bits.2 | mask
        case 3: set.fds_bits.3 = set.fds_bits.3 | mask
        case 4: set.fds_bits.4 = set.fds_bits.4 | mask
        case 5: set.fds_bits.5 = set.fds_bits.5 | mask
        case 6: set.fds_bits.6 = set.fds_bits.6 | mask
        case 7: set.fds_bits.7 = set.fds_bits.7 | mask
        case 8: set.fds_bits.8 = set.fds_bits.8 | mask
        case 9: set.fds_bits.9 = set.fds_bits.9 | mask
        case 10: set.fds_bits.10 = set.fds_bits.10 | mask
        case 11: set.fds_bits.11 = set.fds_bits.11 | mask
        case 12: set.fds_bits.12 = set.fds_bits.12 | mask
        case 13: set.fds_bits.13 = set.fds_bits.13 | mask
        case 14: set.fds_bits.14 = set.fds_bits.14 | mask
        case 15: set.fds_bits.15 = set.fds_bits.15 | mask
        case 16: set.fds_bits.16 = set.fds_bits.16 | mask
        case 17: set.fds_bits.17 = set.fds_bits.17 | mask
        case 18: set.fds_bits.18 = set.fds_bits.18 | mask
        case 19: set.fds_bits.19 = set.fds_bits.19 | mask
        case 20: set.fds_bits.20 = set.fds_bits.20 | mask
        case 21: set.fds_bits.21 = set.fds_bits.21 | mask
        case 22: set.fds_bits.22 = set.fds_bits.22 | mask
        case 23: set.fds_bits.23 = set.fds_bits.23 | mask
        case 24: set.fds_bits.24 = set.fds_bits.24 | mask
        case 25: set.fds_bits.25 = set.fds_bits.25 | mask
        case 26: set.fds_bits.26 = set.fds_bits.26 | mask
        case 27: set.fds_bits.27 = set.fds_bits.27 | mask
        case 28: set.fds_bits.28 = set.fds_bits.28 | mask
        case 29: set.fds_bits.29 = set.fds_bits.29 | mask
        case 30: set.fds_bits.30 = set.fds_bits.30 | mask
        case 31: set.fds_bits.31 = set.fds_bits.31 | mask
        default: break
        }
    }


    /// Replacement for FD_CLR macro

    func fdClr(fd: Int32, inout set: fd_set) {
        let intOffset = Int(fd / 32)
        let bitOffset = fd % 32
        let mask = ~(1 << bitOffset)
        switch intOffset {
        case 0: set.fds_bits.0 = set.fds_bits.0 & mask
        case 1: set.fds_bits.1 = set.fds_bits.1 & mask
        case 2: set.fds_bits.2 = set.fds_bits.2 & mask
        case 3: set.fds_bits.3 = set.fds_bits.3 & mask
        case 4: set.fds_bits.4 = set.fds_bits.4 & mask
        case 5: set.fds_bits.5 = set.fds_bits.5 & mask
        case 6: set.fds_bits.6 = set.fds_bits.6 & mask
        case 7: set.fds_bits.7 = set.fds_bits.7 & mask
        case 8: set.fds_bits.8 = set.fds_bits.8 & mask
        case 9: set.fds_bits.9 = set.fds_bits.9 & mask
        case 10: set.fds_bits.10 = set.fds_bits.10 & mask
        case 11: set.fds_bits.11 = set.fds_bits.11 & mask
        case 12: set.fds_bits.12 = set.fds_bits.12 & mask
        case 13: set.fds_bits.13 = set.fds_bits.13 & mask
        case 14: set.fds_bits.14 = set.fds_bits.14 & mask
        case 15: set.fds_bits.15 = set.fds_bits.15 & mask
        case 16: set.fds_bits.16 = set.fds_bits.16 & mask
        case 17: set.fds_bits.17 = set.fds_bits.17 & mask
        case 18: set.fds_bits.18 = set.fds_bits.18 & mask
        case 19: set.fds_bits.19 = set.fds_bits.19 & mask
        case 20: set.fds_bits.20 = set.fds_bits.20 & mask
        case 21: set.fds_bits.21 = set.fds_bits.21 & mask
        case 22: set.fds_bits.22 = set.fds_bits.22 & mask
        case 23: set.fds_bits.23 = set.fds_bits.23 & mask
        case 24: set.fds_bits.24 = set.fds_bits.24 & mask
        case 25: set.fds_bits.25 = set.fds_bits.25 & mask
        case 26: set.fds_bits.26 = set.fds_bits.26 & mask
        case 27: set.fds_bits.27 = set.fds_bits.27 & mask
        case 28: set.fds_bits.28 = set.fds_bits.28 & mask
        case 29: set.fds_bits.29 = set.fds_bits.29 & mask
        case 30: set.fds_bits.30 = set.fds_bits.30 & mask
        case 31: set.fds_bits.31 = set.fds_bits.31 & mask
        default: break
        }
    }


    /// Replacement for FD_ISSET macro

    func fdIsSet(fd: Int32, inout set: fd_set) -> Bool {
        let intOffset = Int(fd / 32)
        let bitOffset = fd % 32
        let mask = 1 << bitOffset
        switch intOffset {
        case 0: return set.fds_bits.0 & mask != 0
        case 1: return set.fds_bits.1 & mask != 0
        case 2: return set.fds_bits.2 & mask != 0
        case 3: return set.fds_bits.3 & mask != 0
        case 4: return set.fds_bits.4 & mask != 0
        case 5: return set.fds_bits.5 & mask != 0
        case 6: return set.fds_bits.6 & mask != 0
        case 7: return set.fds_bits.7 & mask != 0
        case 8: return set.fds_bits.8 & mask != 0
        case 9: return set.fds_bits.9 & mask != 0
        case 10: return set.fds_bits.10 & mask != 0
        case 11: return set.fds_bits.11 & mask != 0
        case 12: return set.fds_bits.12 & mask != 0
        case 13: return set.fds_bits.13 & mask != 0
        case 14: return set.fds_bits.14 & mask != 0
        case 15: return set.fds_bits.15 & mask != 0
        case 16: return set.fds_bits.16 & mask != 0
        case 17: return set.fds_bits.17 & mask != 0
        case 18: return set.fds_bits.18 & mask != 0
        case 19: return set.fds_bits.19 & mask != 0
        case 20: return set.fds_bits.20 & mask != 0
        case 21: return set.fds_bits.21 & mask != 0
        case 22: return set.fds_bits.22 & mask != 0
        case 23: return set.fds_bits.23 & mask != 0
        case 24: return set.fds_bits.24 & mask != 0
        case 25: return set.fds_bits.25 & mask != 0
        case 26: return set.fds_bits.26 & mask != 0
        case 27: return set.fds_bits.27 & mask != 0
        case 28: return set.fds_bits.28 & mask != 0
        case 29: return set.fds_bits.29 & mask != 0
        case 30: return set.fds_bits.30 & mask != 0
        case 31: return set.fds_bits.31 & mask != 0
        default: return false
        }
    }

    func sockaddrDescription(addr: UnsafePointer<sockaddr>) -> (String?, String?) {

        var host : String?
        var service : String?

        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        var serviceBuffer = [CChar](count: Int(NI_MAXSERV), repeatedValue: 0)

        if getnameinfo(
            addr,
            socklen_t(addr.memory.sa_len),
            &hostBuffer,
            socklen_t(hostBuffer.count),
            &serviceBuffer,
            socklen_t(serviceBuffer.count),
            NI_NUMERICHOST | NI_NUMERICSERV)

            == 0 {

                host = String.fromCString(hostBuffer)
                service = String.fromCString(serviceBuffer)
        }
        return (host, service)

    }

    func initServerSocket() -> Int32? {

        // General purpose status variable, used to detect error returns from socket functions
        var status: Int32 = 0

        // ==================================================================
        // Retrieve the information necessary to create the socket descriptor
        // ==================================================================

        // Protocol configuration, used to retrieve the data needed to create the socket descriptor

        var hints = addrinfo(
            ai_flags: AI_PASSIVE,       // Assign the address of the local host to the socket structures
            ai_family: AF_UNSPEC,       // Either IPv4 or IPv6
            ai_socktype: self.layer == .UDP ? SOCK_DGRAM : SOCK_STREAM,
            ai_protocol: self.layer == .UDP ? IPPROTO_UDP : 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)


        // For the information needed to create a socket (result from the getaddrinfo)

        var servinfo = UnsafeMutablePointer<addrinfo>()


        // Get the info we need to create our socket descriptor

        status = getaddrinfo(
            nil,                        // Any interface
            String(self.port),          // The port on which will be listenend
            &hints,                     // Protocol configuration as per above
            &servinfo)                  // The created information

        if status != 0 {
            let strError = String(UTF8String: gai_strerror(status)) ?? "Unknown error code"
            let message = "Getaddrinfo Error \(status) (\(strError))"
            print(message)
            return nil
        }

        // Print a list of the found IP addresses
//        for (var info = servinfo; info != nil; info = info.memory.ai_next) {
//            let (clientIp, service) = sockaddrDescription(info.memory.ai_addr)
//            let message = "HostIp: " + (clientIp ?? "?") + " at port: " + (service ?? "?")
//            print(message)
//        }

        // ============================
        // Create the socket descriptor
        // ============================

        let socketDescriptor = socket(
            servinfo.memory.ai_family,      // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo.memory.ai_socktype,    // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo.memory.ai_protocol)    // Use the servinfo created earlier, this makes it IPv4/IPv6 independant

//        print("Socket value: \(socketDescriptor)")

        if socketDescriptor == -1 {
            let strError = String(UTF8String: strerror(errno)) ?? "Unknown error code"
            let message = "Socket creation error \(errno) (\(strError))"
            print(message)
            freeaddrinfo(servinfo)
            return nil
        }


        // ========================================================================
        // Set the socket options (specifically: prevent the "socket in use" error)
        // ========================================================================

        var optval: Int = 1; // Use 1 to enable the option, 0 to disable

        status = setsockopt(
            socketDescriptor,               // The socket descriptor of the socket on which the option will be set
            SOL_SOCKET,                     // Type of socket options
            SO_REUSEADDR,                   // The socket option id
            &optval,                        // The socket option value
            socklen_t(sizeof(Int)))         // The size of the socket option value

        if status == -1 {
            let strError = String(UTF8String: strerror(errno)) ?? "Unknown error code"
            let message = "Setsockopt error \(errno) (\(strError))"
            print(message)
            freeaddrinfo(servinfo)
            close(socketDescriptor)         // Ignore possible errors
            return nil
        }

        // ====================================
        // Bind the socket descriptor to a port
        // ====================================

        status = bind(
            socketDescriptor,               // The socket descriptor of the socket to bind
            servinfo.memory.ai_addr,        // Use the servinfo created earlier, this makes it IPv4/IPv6 independant
            servinfo.memory.ai_addrlen)     // Use the servinfo created earlier, this makes it IPv4/IPv6 independant

        freeaddrinfo(servinfo)

        if status != 0 {
            let strError = String(UTF8String: strerror(errno)) ?? "Unknown error code"
            let message = "Binding error \(errno) (\(strError))"
            print(message)
            close(socketDescriptor)         // Ignore possible errors
            return nil
        }

        return socketDescriptor
    }


    func acceptConnectionRequests(socketDescriptor:Int32) {

        // ========================================
        // Start listening for incoming connections
        // ========================================
        
        let status = listen(
            socketDescriptor,                     // The socket on which to listen
            maxNumberOfConnectionsBeforeAccept)   // The number of connections that will be allowed before they are accepted
        
        if status != 0 {
            let strError = String(UTF8String: strerror(errno)) ?? "Unknown error code"
            let message = "Listen error \(errno) (\(strError))"
            print(message)
            close(socketDescriptor)         // Ignore possible errors
            return
        }

        // Incoming connections will be executed in this queue (in parallel)

        let connectionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

        // ========================
        // Start the "endless" loop
        // ========================

        ACCEPT_LOOP: while true {

            // =======================================
            // Wait for an incoming connection request
            // =======================================

            var connectedAddrInfo = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            var connectedAddrInfoLength = socklen_t(sizeof(sockaddr))

            let requestDescriptor = accept(socketDescriptor, &connectedAddrInfo, &connectedAddrInfoLength)

            if requestDescriptor == -1 {
                let strerr = String(UTF8String: strerror(errno)) ?? "Unknown error code"
                let message = "Accept error \(errno) " + strerr
                print(message)
                continue
            }

            //        let (ipAddress, servicePort) = sockaddrDescription(&connectedAddrInfo)
            //        let message = "Accepted connection from: " + (ipAddress ?? "nil") + ", from port:" + (servicePort ?? "nil")
            //        print(message)


            // ==========================================================================
            // Request processing of the connection request in a different dispatch queue
            // ==========================================================================

            dispatch_async(connectionQueue, {
                self.receiveAndDispatch(requestDescriptor)
            })
        }
    }

    func requestIsComplete(status:Int32) -> Bool {
        return status == 0
    }


    func receiveAndDispatch(socket: Int32) {

        let numOfFd:Int32 = socket + 1
        var readSet:fd_set = fd_set(fds_bits: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        var timeout:timeval = timeval(tv_sec: 10, tv_usec: 0)

        fdSet(socket, set:&readSet)

        // =========================================================================================
        // This loop stays active until an error occurs or all data is received
        // =========================================================================================

        while true {

            // =====================================================================================
            // Use the select API to wait for anything to happen on our client socket only within
            // the timeout period
            // Because we only specified 1 FD, we do not need to check on which FD the event was received
            // =====================================================================================

            let status = select(numOfFd, &readSet, nil, nil, &timeout)

            // =====================================================================================
            // In case of a timeout, close the connection
            // =====================================================================================

            if status == 0 {
                print("client timeout")
                close(socket)
                return
            }

            // =====================================================================================
            // In case of an error, close the connection
            // =====================================================================================

            if status == -1 {

                let errString = String(UTF8String: strerror(errno)) ?? "Unknown error code"
                let message = "Error during select, message = \(errno) (\(errString))"
                print(message)
                close(socket)
                return
            }

            // =====================================================================================
            // Use the recv API to see what happened
            // =====================================================================================

            let bufferSize = 1000 // Application dependant
            var requestLength = 0
            var requestBuffer = [Int8](count:10000, repeatedValue:0)
            let bytesRead = recv(socket, &requestBuffer[requestLength], bufferSize, 0)

            // =====================================================================================
            // In case of an error, close the connection
            // =====================================================================================

            if bytesRead == -1 {
                let errString = String(UTF8String: strerror(errno)) ?? "Unknown error code"
                print("Recv error = \(errno) (\(errString))")

                // The connection might still support a transfer, it could be tried to get a message to the client.
                // Not in this example though.
                close(socket)
                return
            }

            // =====================================================================================
            // If the client closed the connection, close our end too
            // =====================================================================================

            if bytesRead == 0 {
                print("Client closed connection")
                close(socket)
                return
            }

            // =====================================================================================
            // If the request is completely received, dispatch it to the dispatchQueue
            // =====================================================================================

            requestLength = requestLength + bytesRead

            if bytesRead < bufferSize { // all request bytes were read
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    self.processRequest(socket, data:requestBuffer, length:bytesRead)
//                })
                return
            }
        }
    }

    func processRequest(socket:Int32, data:[Int8], length:Int) {
        let request = NSString(bytes: data, length:length, encoding: NSUTF8StringEncoding)
        print("received request: \(request)")
//        close(socket)
    }

    init(port:Int, layer:TransportLayer) {
        self.port = port
        self.layer = layer
    }

    func serve() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
        
            // =================================================
            // Initialize the port on which we will be listening
            // =================================================

            let httpSocketDescriptor = self.initServerSocket()
            if httpSocketDescriptor == nil {
                exit(-1)
            }

            // ===========================================================================
            // Keep on accepting connection requests until a fatal error or a stop request
            // ===========================================================================

            let acceptQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

            if self.layer == .TCP {
                dispatch_async(acceptQueue, {
                    self.acceptConnectionRequests(httpSocketDescriptor!)
                })
            } else {
            
                while true {
                    dispatch_async(acceptQueue, {
                        self.receiveAndDispatch(httpSocketDescriptor!)
                    })

                }
            }

            self.condition.lock()
            self.condition.wait()
            
        })
    }
}

class TcpServer : IpServer {

    init(port:Int) {
        super.init(port: port, layer:.TCP)
    }
}

class UdpServer : IpServer {

    init(port:Int) {
        super.init(port: port, layer:.UDP)
    }
}

func printlog(line:String) {
    dispatch_async(dispatch_get_main_queue(), {
        ViewController.printlog(line)
    })
}