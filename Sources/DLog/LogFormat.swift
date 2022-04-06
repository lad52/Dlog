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

/// Format options for date.
public enum LogDateFormatter {
    /// Format date with date/time styles and locale.
    /// - Parameters:
    ///    - dateStyle: Format style for date.
    ///    - timeStyle: Format style for time.
    ///    - locale: The locale for the receiver.
    case date(dateStyle: DateFormatter.Style = .none, timeStyle: DateFormatter.Style = .none, locale: Locale? = nil)
    
    /// Format date with a custom format string.
    /// - Parameters:
    ///    - format: Custom format string.
    case dateCustom(format: String)
    
    private static let formatter = DateFormatter()
    
    func string(from date: Date) -> String {
        synchronized(Self.formatter) {
            switch self {

            case let .date(dateStyle, timeStyle, locale):
                Self.formatter.locale = locale
                Self.formatter.dateStyle = dateStyle
                Self.formatter.timeStyle = timeStyle
                return Self.formatter.string(from: date)

            case let .dateCustom(format):
                Self.formatter.dateFormat = format
                return Self.formatter.string(from: date)
            }
        }
    }
}

/// Format options for number.
public enum LogNumberFormatter {
    /// Format number with style and locale.
    /// - Parameters:
    ///   - style: Format style for number.
    ///   - locale: The locale for the receiver.
    case number(style: NumberFormatter.Style, locale: Locale? = nil)
    
    private static let formatter = NumberFormatter()
    
    func string(from number: Int) -> String {
        synchronized(Self.formatter) {
            switch self {
                
            case let .number(style, locale):
                Self.formatter.locale = locale
                Self.formatter.numberStyle = style
                return Self.formatter.string(from: NSNumber(value: number))!
            }
        }
    }
}

public enum LogIntFormatter {
    case binary
    
    case octal(includePrefix: Bool = false)
    public static let octal = Self.octal()
    
    case hex(includePrefix: Bool = false, uppercase: Bool = false)
    public static let hex = Self.hex()
    
    /// Format byte count with style and unit.
    /// - Parameters:
    ///  - countStyle: Style of counts.
    ///  - allowedUnits: Units to display.
    case byteCount(countStyle: ByteCountFormatter.CountStyle = .file, allowedUnits: ByteCountFormatter.Units = .useMB)
    
    private static let byteCountFormatter = ByteCountFormatter()
    
    func string<T: FixedWidthInteger>(from value: T) -> String {
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
        }
    }
}
