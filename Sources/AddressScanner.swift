//
//  AddressScanner.swift
//  Addresses
//
//  Created by Jonathan Wight on 5/16/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Foundation

// MARK: -

internal func + (lhs: NSCharacterSet, rhs: NSCharacterSet) -> NSCharacterSet {
    let scratch = lhs.mutableCopy() as! NSMutableCharacterSet
    scratch.formUnionWithCharacterSet(rhs)
    return scratch
}

internal extension NSCharacterSet {

    class func asciiLetterCharacterSet() -> NSCharacterSet {
        return asciiLowercaseLetterCharacterSet() + asciiUppercaseLetterCharacterSet()
    }

    class func asciiLowercaseLetterCharacterSet() -> NSCharacterSet {
        return NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyz")
    }

    class func asciiUppercaseLetterCharacterSet() -> NSCharacterSet {
        return NSCharacterSet(charactersInString: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    class func asciiDecimalDigitsCharacterSet() -> NSCharacterSet {
        return NSCharacterSet(charactersInString: "0123456789")
    }

    class func asciiAlphanumericCharacterSet() -> NSCharacterSet {
        return asciiLetterCharacterSet() + asciiDecimalDigitsCharacterSet()
    }

    class func asciiHexDigitsCharacterSet() -> NSCharacterSet {
        return asciiDecimalDigitsCharacterSet() + NSCharacterSet(charactersInString: "ABCDEFabcdef")
    }
}

// MARK: -

internal extension NSScanner {

    var remaining: String {
        return (string as NSString).substringFromIndex(scanLocation)
    }

    func with(@noescape closure: () -> Bool) -> Bool {
        let savedCharactersToBeSkipped = charactersToBeSkipped
        let savedLocation = scanLocation
        let result = closure()
        if result == false {
            scanLocation = savedLocation
        }
        charactersToBeSkipped = savedCharactersToBeSkipped
        return result
    }

    func scanString(string: String) -> Bool {
        return scanString(string, intoString: nil)
    }

    func scanBracketedString(openBracket: String, closeBracket: String, inout intoString: String?) -> Bool {
        return with() {
            if scanString(openBracket) == false {
                return false
            }
            var temp: NSString?
            if scanUpToString(closeBracket, intoString: &temp) == false {
                return false
            }
            if scanString(closeBracket) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    func scan(inout intoString: String?, @noescape closure: () -> Bool) -> Bool {
        let savedCharactersToBeSkipped = charactersToBeSkipped
        defer {
            charactersToBeSkipped = savedCharactersToBeSkipped
        }
        let savedLocation = scanLocation
        if closure() == false {
            scanLocation = savedLocation
            return false
        }
        let range = NSRange(location: savedLocation, length: scanLocation - savedLocation)
        intoString = (string as NSString).substringWithRange(range)
        return true
    }

}

// MARK: -

internal extension NSScanner {
    func scanIPV6Address(inout intoString: String?) -> Bool {
        return with() {
            charactersToBeSkipped = nil
            let characterSet = NSCharacterSet.asciiHexDigitsCharacterSet() + NSCharacterSet(charactersInString: ":.")
            var temp: NSString?
            if scanCharactersFromSet(characterSet, intoString: &temp) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    func scanIPV4Address(inout intoString: String?) -> Bool {
        return with() {
            charactersToBeSkipped = nil
            let characterSet = NSCharacterSet.asciiDecimalDigitsCharacterSet() + NSCharacterSet(charactersInString: ".")
            var temp: NSString?
            if scanCharactersFromSet(characterSet, intoString: &temp) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    /// Scan a "domain". Domain is considered a sequence of hostnames seperated by dots.
    func scanDomain(inout intoString: String?) -> Bool {
        let savedLocation = scanLocation
        while true {
            var hostname: String?
            if scanHostname(&hostname) == false {
                break
            }
            if scanString(".") == false {
                break
            }
        }
        let range = NSRange(location: savedLocation, length: scanLocation - savedLocation)
        if range.length == 0 {
            return false
        }
        intoString = (string as NSString).substringWithRange(range)
        return true
    }

    /// Scan a "hostname".
    func scanHostname(inout intoString: String?) -> Bool {
        return with() {
            var output = ""
            var temp: NSString?
            if scanCharactersFromSet(NSCharacterSet.asciiAlphanumericCharacterSet(), intoString: &temp) == false {
                return false
            }
            output += temp! as String
            if scanCharactersFromSet(NSCharacterSet.asciiAlphanumericCharacterSet() + NSCharacterSet(charactersInString: "-"), intoString: &temp) == true {
                output += temp! as String
            }
            intoString = output
            return true
        }
    }

    /// Scan a port/service name. For purposes of this we consider this any alphanumeric sequence and rely on getaddrinfo
    func scanPort(inout intoString: String?) -> Bool {
        let characterSet = NSCharacterSet.asciiAlphanumericCharacterSet() + NSCharacterSet(charactersInString: "-")
        var temp: NSString?
        if scanCharactersFromSet(characterSet, intoString: &temp) == false {
            return false
        }
        intoString = temp! as String
        return true
    }

    /// Scan an address into a hostname and a port. Very crude. Rely on getaddrinfo.
    func scanAddress(inout address: String?, inout port: String?) -> Bool {
        var string: String?

        if scanBracketedString("[", closeBracket: "]", intoString: &string) == true {
            let scanner = NSScanner(string: string!)
            if scanner.scanIPV6Address(&address) == false {
                return false
            }
            if scanner.atEnd == false {
                return false
            }

        }
        else if scanIPV4Address(&address) == true {
            // Nothing to do here
        }
        else if scanDomain(&address) == true {
            // Nothing to do here
        }

        if scanString(":") {
            scanPort(&port)
        }
        return true
    }
}

// MARK: -

public func scanAddress(string: String, inout address: String?, inout service: String?) -> Bool {
    let scanner = NSScanner(string: string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
    scanner.charactersToBeSkipped = nil
    var result = scanner.scanAddress(&address, port: &service)
    if scanner.atEnd == false {
        result = false
    }
    if result == false {
        address = nil
        service = nil
    }
    return result
}

