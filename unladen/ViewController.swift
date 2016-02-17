import Cocoa

extension NSTextView {
    func append(string: String) {
        let oldString = self.string == nil ? "" : self.string!
        let newString = NSString(format: "%@%@", oldString, string)
        self.string = newString as String
    }
}

class ViewController: NSViewController {

    @IBOutlet var logview: NSTextView!

    static var shared :ViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.shared = self
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    static func printlog(line:String) {
        shared?.logview.append(line)
    }
}

