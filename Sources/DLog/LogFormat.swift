//
//  LogFormat.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/02/14.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation
import Network

/// Format options for date.
public enum LogDateFormatting {
    
    /// Displays a date value with the specified parameters.
    ///
    /// - Parameters:
    ///    - dateStyle: Format style for date. The default is `none`.
    ///    - timeStyle: Format style for time. The default is `none`.
    ///    - locale: The locale for the receiver. The default is `nil`.
    case date(dateStyle: DateFormatter.Style = .none, timeStyle: DateFormatter.Style = .none, locale: Locale? = nil)
    
    /// Displays a date value with the specified format.
    ///
    /// - Parameters:
    ///    - format: Custom format string.
    case dateCustom(format: String)
    
    private static let formatter = DateFormatter()
    
    func string(from value: Date) -> String {
        synchronized(Self.formatter) {
            switch self {

            case let .date(dateStyle, timeStyle, locale):
                Self.formatter.locale = locale
                Self.formatter.dateStyle = dateStyle
                Self.formatter.timeStyle = timeStyle
                return Self.formatter.string(from: value)

            case let .dateCustom(format):
                Self.formatter.dateFormat = format
                return Self.formatter.string(from: value)
            }
        }
    }
}

/// Format options for integers.
public enum LogIntFormatting {
    /// Displays an integer value in binary format.
    case binary
    
    /// Displays an integer value in octal format with the specified parameters.
    ///
    /// - Parameters:
    ///   - includePrefix: Pass `true` to add a prefix 0o. The default is `false`.
    case octal(includePrefix: Bool = false)
    
    /// Displays an integer value in octal format.
    public static let octal = Self.octal()
    
    /// Displays an integer value in hexadecimal format with the specified
    /// parameters.
    ///
    /// - Parameters:
    ///   - includePrefix: Pass `true` to add a prefix 0x. The default is `false`.
    ///   - uppercase: Pass `true` to use uppercase letters
    ///   or `false` to use lowercase letters. The default is `false`.
    case hex(includePrefix: Bool = false, uppercase: Bool = false)
    
    /// Displays an integer value in hexadecimal format.
    public static let hex = Self.hex()
    
    /// Displays an integer value in byte count format with the specified parameters.
    ///
    /// - Parameters:
    ///  - countStyle: Style of counts. The default is `file`.
    ///  - allowedUnits: Units to display. The default is `useMB`.
    case byteCount(countStyle: ByteCountFormatter.CountStyle = .file, allowedUnits: ByteCountFormatter.Units = .useMB)
    
    /// Displays an integer value in byte count format.
    public static let byteCount = Self.byteCount(allowedUnits: .useAll)
    
    /// Displays an integer value in number format with the specified parameters.
    ///
    /// - Parameters:
    ///   - style: Format style for number.
    ///   - locale: The locale for the receiver. The default is `nil`.
    case number(style: NumberFormatter.Style, locale: Locale? = nil)
    
    /// Displays an integer value in number format.
    public static let number = Self.number(style: .decimal)
    
    /// Displays a localized string corresponding to a specified HTTP status code.
    case httpStatusCode
    
    /// Displays an integer value (Int32) as IPv4 address.
    ///
    /// For instance, 0x0100007f would be displayed as 127.0.0.1
    case ipv4Address
    
    // Formatters
    private static let byteCountFormatter = ByteCountFormatter()
    private static let numberFormatter = NumberFormatter()
    
    func string<T: BinaryInteger>(from value: T) -> String {
        switch self {
        case .binary:
            return String(value, radix: 2)
            
        case let .octal(includePrefix):
            let prefix = includePrefix ? "0o" : ""
            let oct = String(value, radix: 8)
            return "\(prefix)\(oct)"
            
        case let .hex(includePrefix, uppercase):
            let prefix = includePrefix ? "0x" : ""
            let hex = String(value, radix: 16, uppercase: uppercase)
            return "\(prefix)\(hex)"
            
        case let .byteCount(countStyle, allowedUnits):
            return synchronized(Self.byteCountFormatter) {
                Self.byteCountFormatter.countStyle = countStyle
                Self.byteCountFormatter.allowedUnits = allowedUnits
                return Self.byteCountFormatter.string(fromByteCount: Int64(value))
            }
        
        case let .number(style, locale):
            return synchronized(Self.numberFormatter) {
                Self.numberFormatter.locale = locale
                Self.numberFormatter.numberStyle = style
                return Self.numberFormatter.string(from: NSNumber(value: Double(value)))!
            }
            
        case .httpStatusCode:
            return "HTTP \(value) \(HTTPURLResponse.localizedString(forStatusCode: Int(value)))"
            
        case .ipv4Address:
            guard value >= 0 else { return "" }
            let data = withUnsafeBytes(of: UInt32(value)) { Data($0) }
            return IPv4Address(data)!.debugDescription
        }
    }
}

/// Format options for floating-point numbers.
public enum LogFloatFormatting {
    /// Displays a floating-point value in fprintf's `%f` format with specified precision.
    ///
    /// - Parameters:
    ///  - precision: Number of digits to display after the radix point.
    case fixed(precision: Int = 0)
    
    /// Displays a floating-point value in fprintf's `%f` format with default precision.
    public static let fixed = Self.fixed()
    
    /// Displays a floating-point value in hexadecimal format with the specified parameters.
    ///
    /// - Parameters:
    ///   - includePrefix: Pass `true` to add a prefix 0x. The default is `false`.
    ///   - uppercase: Pass `true` to use uppercase letters
    ///    or `false` to use lowercase letters. The default is `false`.
    case hex(includePrefix: Bool = false, uppercase: Bool = false)
    
    /// Displays a floating-point value in hexadecimal format.
    public static let hex = Self.hex()
    
    /// Displays a floating-point value in fprintf's `%e` format with specified precision.
    ///
    /// - Parameters:
    ///   - precision: Number of digits to display after the radix point.
    case exponential(precision: Int = 0)
    
    /// Displays a floating-point value in fprintf's `%e` format.
    public static let exponential = Self.exponential()
    
    /// Displays a floating-point value in fprintf's `%g` format with the
    /// specified precision.
    ///
    /// - Parameters:
    ///   - precision: Number of digits to display after the radix point.
    case hybrid(precision: Int = 0)
    
    /// Displays a floating-point value in fprintf's `%g` format.
    public static let hybrid = Self.hybrid()
    
    /// Displays a floating-point value in number format with the specified parameters.
    ///
    /// - Parameters:
    ///   - style: Format style for number.
    ///   - locale: The locale for the receiver. The default is `nil`.
    case number(style: NumberFormatter.Style, locale: Locale? = nil)
    
    /// Displays a floating-point value in number format.
    public static let number = Self.number(style: .decimal)
    
    // Formatters
    private static let numberFormatter = NumberFormatter()
    
    func string<T: BinaryFloatingPoint>(from value: T) -> String {
        switch self {
        case let .fixed(precision):
            return precision > 0
                ? String(format: "%.\(precision)f", Double(value))
                : String(format: "%f", Double(value))
            
        case let .hex(includePrefix, uppercase):
            var text = String(format: "%a", Double(value)).replacingOccurrences(of: "0x", with: "")
            if uppercase {
                text = text.uppercased()
            }
            return "\(includePrefix ? "0x" : "")\(text)"
            
        case let .exponential(precision):
            return precision > 0
                ? String(format: "%.\(precision)e", Double(value))
                : String(format: "%e", Double(value))
            
        case let .hybrid(precision):
            return precision > 0
                ? String(format: "%.\(precision)g", Double(value))
                : String(format: "%g", Double(value))
            
        case let .number(style, locale):
            return synchronized(Self.numberFormatter) {
                Self.numberFormatter.locale = locale
                Self.numberFormatter.numberStyle = style
                return Self.numberFormatter.string(from: NSNumber(value: Double(value)))!
            }
        }
    }
}

/// The formatting options for Boolean values.
public enum LogBoolFormatting {
    /// Displays a boolean value as 1 or 0.
    case binary
    
    /// Displays a boolean value as yes or no.
    case answer
    
    /// Displays a boolean value as on or off.
    case toggle
    
    func string(from value: Bool) -> String {
        switch self {
        case .binary:
            return value ? "1" : "0"
            
        case .toggle:
            return value ? "on" : "off"
            
        case .answer:
            return value ? "yes" : "no"
        }
    }
}
