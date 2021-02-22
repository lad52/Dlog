//
//  Text.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/03.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
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


enum ANSIEscapeCode: String {
	case reset = "\u{001b}[0m"
	case clear = "\u{001b}c"
	
	case bold = "\u{001b}[1m"
	case dim = "\u{001b}[2m"
	case underline = "\u{001b}[4m"
	case blink = "\u{001b}[5m"
	case reversed = "\u{001b}[7m"
	
	// 8 colors
	case textBlack = "\u{001B}[30m"
	case textRed = "\u{001B}[31m"
	case textGreen = "\u{001B}[32m"
	case textYellow = "\u{001B}[33m"
	case textBlue = "\u{001B}[34m"
	case textMagenta = "\u{001B}[35m"
	case textCyan = "\u{001B}[36m"
	case textWhite = "\u{001B}[37m"
	
	case backgroundBlack = "\u{001b}[40m"
	case backgrounRed = "\u{001b}[41m"
	case backgroundGreen = "\u{001b}[42m"
	case backgroundYellow = "\u{001b}[43m"
	case backgroundBlue = "\u{001b}[44m"
	case backgroundMagenta = "\u{001b}[45m"
	case backgroundCyan = "\u{001b}[46m"
	case backgroundWhite = "\u{001b}[47m"
}

private extension String {
	func color(_ codes: [ANSIEscapeCode]) -> String {
		return codes.map { $0.rawValue }.joined() + self + ANSIEscapeCode.reset.rawValue
	}
	
	func color(_ code: ANSIEscapeCode) -> String {
		return color([code])
	}
}

private extension LogType {
	static let icons: [LogType : String] = [
		.log : "💬",
		.trace : "#️⃣",
		.debug : "▶️",
		.info : "✅",
		.warning: "⚠️",
		.error : "⚠️",
		.assert : "🅰️",
		.fault : "🆘",
		
		.interval : "🕒",
		.scope : "",
	]
	
	var icon: String {
		Self.icons[self]!
	}
	
	static let titles: [LogType : String] = [
		.log : "LOG",
		.trace : "TRACE",
		.debug : "DEBUG",
		.info : "INFO",
		.warning : "WARNING",
		.error : "ERROR",
		.assert : "ASSERT",
		.fault : "FAULT",
		
		.interval : "INTERVAL",
		.scope: ""
	]
	
	var title: String {
		Self.titles[self]!
	}
}

public class Text : LogOutput {
	private struct Tag {
		let textColor: ANSIEscapeCode
		let colors: [ANSIEscapeCode]
	}
	
	private static let tags: [LogType : Tag] = [
		.log : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
		.info : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
		.trace : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
		.debug : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
		.warning : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
		.error : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
		.fault : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite, .blink]),
		.assert : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite]),
		.interval : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
		//.scope :
	]
	
	private let startSign = "•"
	
	public enum Style {
		case plain
		case emoji
		case colored
	}
	
	let style: Style
	
	public init(style: Style = .plain) {
		self.style = style
		
		super.init(source: nil)
	}
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm:ss.SSS"
		return dateFormatter
	}()
	
	static let dateComponentsFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		return formatter
	}()
	
	private func stringFromTime(interval: TimeInterval) -> String {
		let ms = String(format:"%.03f", interval).suffix(3)
		return Self.dateComponentsFormatter.string(from: interval)! + ".\(ms)"
	}
	
	private func textMessage(item: LogItem, scopes: [LogScope]) -> String {
		assert(item.time != nil)
		let time = item.time != nil ? Self.dateFormatter.string(from: item.time!) : ""
		
		var padding = ""
		if let scope = item.scope, scope.entered {
			for level in 1...scope.level {
				let scope = scopes.first(where: { $0.level == level })
				padding += scope != nil ? "|\t" : " \t"
			}
		}
		
		let level = String(format: "[%02d]", item.scope?.level ?? 0)
		
		switch style {
			case .colored:
				guard let tag = Self.tags[item.type] else { fallthrough }
				
				let tagText = " \(item.type.title) ".color(tag.colors)
				let location = "<\(item.fileName):\(item.line)>".color([.dim, tag.textColor])
				return "\(startSign.color(.dim)) \(time.color(.dim)) \(level.color(.dim)) \(item.category.color(.textBlue)) \(padding)\(tagText) \(location) \(item.text.color(tag.textColor))"
				
			case .plain:
				return "\(startSign) \(time) \(level) [\(item.category)] \(padding)[\(item.type.title)] <\(item.fileName):\(item.line)> \(item.text)"
				
			case .emoji:
				return "\(startSign) \(time) \(level) [\(item.category)] \(padding)\(item.type.icon) [\(item.type.title)] <\(item.fileName):\(item.line)> \(item.text)"
		}
	}

	private func textScope(scope: LogScope, scopes: [LogScope]) -> String {
		guard let scopeTime = scope.time else {
			return ""
		}
		
		var start = true
		var time = Self.dateFormatter.string(from: scopeTime)
		var ms: String?
		
		if scope.duration > 0 {
			start = false
			time = Self.dateFormatter.string(from: scopeTime.addingTimeInterval(scope.duration))
			ms = "(\(stringFromTime(interval: scope.duration))s)"
		}
		
		var padding = ""
		for level in 1..<scope.level {
			let scope = scopes.first(where: { $0.level == level })
			padding += scope != nil ? "|\t" : " \t"
		}
		padding += start ? "┌" : "└"
		
		let level = String(format: "[%02d]", scope.level)
		
		switch style {
			case .emoji, .plain:
				return "\(startSign) \(time) \(level) [\(scope.category)] \(padding) [\(scope.text)] \(ms ?? "")"
				
			case .colored:
				return "\(startSign.color(.dim)) \(time.color(.dim)) \(level.color(.dim)) \(scope.category.color(.textBlue)) \(padding) [\(scope.text.color(.textMagenta))] \(ms ?? "")"
		}
	}
	
	// MARK: - LogOutput
	
	override func log(item: LogItem, scopes: [LogScope]) -> String? {
		super.log(item: item, scopes: scopes)
		return textMessage(item: item, scopes: scopes)
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeEnter(scope: scope, scopes: scopes)

		return textScope(scope: scope, scopes: scopes)
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeLeave(scope: scope, scopes: scopes)
		
		return textScope(scope: scope, scopes: scopes)
	}
	
	override func intervalBegin(interval: LogInterval) {
		super.intervalBegin(interval: interval)
	}
	
	override func intervalEnd(interval: LogInterval, scopes: [LogScope]) -> String? {
		super.intervalEnd(interval: interval, scopes: scopes)
		
		let duration = stringFromTime(interval: interval.duration)
		let total = stringFromTime(interval: interval.total)
		let min = stringFromTime(interval: interval.min)
		let max = stringFromTime(interval: interval.max)
		let avg = stringFromTime(interval: interval.avg)
		interval.text = "\(interval.name) - count: \(interval.count), duration: \(duration)s, total: \(total)s, min: \(min)s, max: \(max)s, avg: \(avg)s"
		
		return textMessage(item: interval, scopes: scopes)
	}
}
