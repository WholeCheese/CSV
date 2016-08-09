//
//  AppDelegate.swift
//  CSV
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

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CSVParserDelegate
{
	var exampleStart: NSDate?

	func applicationDidFinishLaunching(aNotification: NSNotification)
	{
		// Insert code here to initialize your application

//		doStuff()	//	Use this to time really big files.
	}

	func applicationWillTerminate(aNotification: NSNotification)
	{
		// Insert code here to tear down your application
	}

	func doStuff()
	{
		exampleStart = NSDate()

		let pathName = "/path/to/a/really/big/file.csv"
		let csv = CSVParser(path: pathName, delegate: self)
		let workQueue = dispatch_queue_create("doStuff!", DISPATCH_QUEUE_SERIAL)
		dispatch_async(workQueue)
		{
			csv.startReader()
		}
	}

	func parserDidStartDocument(parser: CSVParser)
	{
		var name = ""
		let pathComponents = parser.csvFile.path.componentsSeparatedByString("/")

		if let n = pathComponents.last
		{
			name = n
		}
		NSLog("\n")
		NSLog("Did start document: \(name)")
	}

	func parserDidReadLine(parser: CSVParser, line: [String])
	{
//		print("\nline: \(parser.lineCount), \(line.count) fields: \(line)")
//		for field in line
//		{
//			print("|\(field)|")
//		}
	}

	func parserDidEndDocument(parser: CSVParser)
	{
		NSLog("\nDid end document: \(parser.lineCount) lines read.")
		NSLog("Finish time: \(NSDate().timeIntervalSinceDate(exampleStart!))")
		NSLog("\n")
	}
}
