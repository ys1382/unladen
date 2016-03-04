import Foundation

// todo: make extensions to NSData
func data2bytes(data:NSData) -> [UInt8] {
    let count = data.length / sizeof(UInt8)
    var array = [UInt8](count: count, repeatedValue: 0)
    data.getBytes(&array, length:count * sizeof(UInt8))
    return array
}

class Connection: NSObject, NSStreamDelegate {
    var host:String
    var port:UInt16
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    typealias Callback = (data:[UInt8]) -> NSData?;
    var requested : Callback

    init(host: String, port: UInt16, callback:Callback) {

        self.host = host
        self.port = port
        self.requested = callback
        super.init()
    }

    func connect() {

        NSStream.getStreamsToHostWithName(host, port: Int(self.port), inputStream: &inputStream, outputStream: &outputStream)

        if inputStream != nil && outputStream != nil {

            // Set delegate
            inputStream!.delegate = self
            outputStream!.delegate = self

            // Schedule
            inputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            outputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)

            print("Start open()")

            // Open!
            inputStream!.open()
            outputStream!.open()
        }
    }
    

    func send(data:NSData) {
        let buffer = data2bytes(data)
        outputStream?.write(buffer, maxLength:buffer.count)
    }

    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        if aStream === inputStream {
            switch eventCode {
            case NSStreamEvent.ErrorOccurred:
                print("input: ErrorOccurred: \(aStream.streamError?.description)")
            case NSStreamEvent.OpenCompleted:
                print("input: OpenCompleted")
            case NSStreamEvent.HasBytesAvailable:
                print("input: HasBytesAvailable")

                var buffer = [UInt8](count: 4096, repeatedValue: 0)

                while (inputStream!.hasBytesAvailable){
                    if inputStream!.read(&buffer, maxLength: buffer.count) > 0 {
                        let output = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
                        NSLog("server said: %@", output!)
                        self.requested(data:buffer)
                    }
                }

            default:
                break
            }
        }
        else if aStream === outputStream {
            switch eventCode {
            case NSStreamEvent.ErrorOccurred:
                print("output: ErrorOccurred: \(aStream.streamError?.description)")
            case NSStreamEvent.OpenCompleted:
                print("output: OpenCompleted")
            case NSStreamEvent.HasSpaceAvailable:
                print("output: HasSpaceAvailable")

                // Here you can write() to `outputStream`

            default:
                break
            }
        }
    }
}