import Foundation
import SwiftyBeaver

class SwiftyBeaverLog {
    static let shared = SwiftyBeaverLog()
    let log = SwiftyBeaver.self
    private init() {
        setupLogger()
    }
    
    private func setupLogger() {
        let console = ConsoleDestination()
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M"
        console.minLevel = .info
                
        log.removeAllDestinations()
        log.addDestination(console)
        
        log.info("log system initialized")
    }
}

enum Logger {
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        SwiftyBeaverLog.shared.log.verbose(message, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        SwiftyBeaverLog.shared.log.debug(message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        SwiftyBeaverLog.shared.log.info(message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        SwiftyBeaverLog.shared.log.warning(message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        SwiftyBeaverLog.shared.log.error(message, file: file, function: function, line: line)
    }
}
