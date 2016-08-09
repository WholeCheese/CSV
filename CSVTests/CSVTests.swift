//
//  CSVTests.swift
//  CSVTests
//
//  Created by Allan Hoeltje on 8/2/16.
//  Copyright © 2016 Allan Hoeltje.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import XCTest
@testable import CSV

class CSVTests: XCTestCase, CSVParserDelegate
{
	var example2Start: NSDate?

	override func setUp()
	{
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown()
	{
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func test01()
	{
		//	Test01 - Simple CSV file using LF line termination.
		let csv1 = CSVParser(path: bundlePath("test01", type: "csv"), delegate: self)
		csv1.startReader(",")

		//	Test02 - Simple CSV file using an unusual separator character.
		//	Missing the LF on the last line.
		let csv2 = CSVParser(path: bundlePath("test02", type: "csv"), delegate: self)
		csv2.startReader("😀")

		//	Test03 - Korean, Japanese, and Chinese text using CRLF line termination.
		let csv3 = CSVParser(path: bundlePath("test03", type: "csv"), delegate: self)
		csv3.startReader()

		//	Test04 - CRLF file with a quoted field containing a CRLF.
		let csv4 = CSVParser(path: bundlePath("test04", type: "csv"), delegate: self)
		csv4.startReader()

		//	Test05 - Field combinations with spaces and quotes.
		let csv5 = CSVParser(path: bundlePath("test05", type: "csv"), delegate: self)
		csv5.startReader()

		//	Test06 - City names with latitude and longitude containing quote characters.
		let csv6 = CSVParser(path: bundlePath("test06", type: "csv"), delegate: self)
		csv6.startReader()

		//	Test07 - Cars for sale.
		let csv7 = CSVParser(path: bundlePath("test07", type: "csv"), delegate: self)
		csv7.startReader(",")

		//	Test08 - Same cars for sale but with a TAB separator and using CRLF line termination.
		let csv8 = CSVParser(path: bundlePath("test08", type: "csv"), delegate: self)
		csv8.startReader("\t")
	}


	func bundlePath(fileName: String, type: String) -> String
	{
		return NSBundle(forClass: self.dynamicType).pathForResource(fileName, ofType: type)!
	}


	//	MARK: ----- CSVParserDelegate methods -----

	/// sent when the parser begins parsing the document.
	/// - Parameters:
	///   - parser: the CSVParser object
	func parserDidStartDocument(parser: CSVParser)
	{
		var name = ""
		let pathComponents = parser.csvFile.path.componentsSeparatedByString("/")

		if let n = pathComponents.last
		{
			name = n
		}
		print("\n")
		print("Did start document: \(name)")
		example2Start = NSDate()
	}

	/// sent to the delegate for each line in the CSV document
	/// - Parameters:
	///   - parser: the CSVParser object
	///   - line: an array of strings, one element for each delimited field in the line
	func parserDidReadLine(parser: CSVParser, line: [String])
	{
		print("\nline: \(parser.lineCount), \(line.count) fields: \(line)")
		for field in line
		{
			print("|\(field)|")
		}

		//	TODO: we need to test the expected values here.
	}

	/// sent when the parser has completed parsing. If this is encountered, the parse was successful.
	/// - Parameters:
	///   - parser: the CSVParser object
	func parserDidEndDocument(parser: CSVParser)
	{
		print("\nDid end document: \(parser.lineCount) lines read.")
		print("Finish time: \(NSDate().timeIntervalSinceDate(example2Start!))")
		print("\n")
	}
}
