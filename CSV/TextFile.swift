//
//  TextFile.swift
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

import Foundation

/// A class representing a text file.
public class TextFile
{
	var path: String
	var encoding: NSStringEncoding

	/// Initializes a text file from a path using NSUTF8StringEncoding.
	///
	/// - Parameter path: The path to be created a text file from.
	public init(path: String)
	{
		self.encoding = NSUTF8StringEncoding
		self.path = path
	}

	/// Initializes a text file from a path with an encoding.
	///
	/// - Parameter path: The path to be created a text file from.
	/// - Parameter encoding: The encoding to be used for the text file.
	public init(path: String, encoding: NSStringEncoding)
	{
		self.encoding = encoding
		self.path = path
	}

	/// Initializes a text file reader.
	///
	/// - Parameter bufferSize: The byte size of the read buffer.  Defaults to 4096 bytes.
	/// - Returns: A text file StreamReader.
	public func reader(bufferSize: Int = 4096) -> StreamReader?
	{
		return StreamReader(
			path: self.path,
			encoding: encoding,
			bufferSize: bufferSize
		)
	}

	//	TODO: make a writer too!
}


/// A class to read a text file one line at a time.
public class StreamReader
{
	var fileHandle: NSFileHandle?
	var atEOF: Bool = false
	let encoding: NSStringEncoding
	let bufferSize: Int
	var lineData: [UInt8]
	var lineIndex = 0
	var tmpData = NSData()
	var buffer = NSData()
	var beginByte = 0
	let crDelim: UInt8 = 13		//	0x0D "\r"
	let lfDelim: UInt8 = 10		//	0x0A "\n"
	var crWasSeen = false

	init?(
		path: String,
		encoding: NSStringEncoding = NSUTF8StringEncoding,
		bufferSize: Int = 4096
		)
	{
		self.bufferSize = bufferSize
		self.encoding = encoding
		self.lineData = [UInt8](count: bufferSize, repeatedValue: 0)
		self.lineData.removeAll(keepCapacity: true)

		do
		{
			let fileURL = NSURL(fileURLWithPath: path)

			self.fileHandle = try NSFileHandle(forReadingFromURL: fileURL)

			//self.fileHandle = NSFileHandle(forReadingAtPath: path)
			if self.fileHandle != nil
			{

				//	TODO: examine the first 1024 bytes or so to determine if this is a "text" file.
			}
			else
			{
				return nil
			}
		}
		catch let e
		{
			let error = e as NSError

			print("localizedDescription: \(error.localizedDescription)")
			//	localizedDescription: The operation couldn’t be completed. (Cocoa error 2.)
			if let reason = error.localizedFailureReason
			{
				print("\(reason)")
			}
			print("error! \(error)")

			return nil
		}
	}

	deinit
	{
		self.close()
		self.lineData.removeAll()
	}


	/// Return a line of text.  A "line" is any string of unicode characters upto but not including the line
	///	terminator.  A line terminator is any of: <cr>, <lf>, or <crlf>
	/// - Returns: The next line or nil on EOF.  Blank lines are returned as the "" empty string.
	public func nextLine() -> String?
	{
		var line: String?

		if fileHandle != nil
		{
			var chars: UnsafePointer<UInt8>
			var atEOL: Bool = false

			lineData.removeAll(keepCapacity: true)

			while !atEOF
			{
				if atEOL
				{
					break
				}
				else
				{
					if beginByte == buffer.length
					{
						beginByte = 0

						buffer = fileHandle!.readDataOfLength( bufferSize )
						if buffer.length == 0
						{
							atEOF = true
							break
						}
					}

					chars = UnsafePointer<UInt8>(buffer.bytes)

					while beginByte < buffer.length
					{
						let byte: UInt8 = chars[beginByte]

						beginByte += 1

						if byte == crDelim
						{
							crWasSeen = true
							atEOL = true
							break
						}
						else
						if byte == lfDelim
						{
							if crWasSeen
							{
								//	for CRLF we treat the CR as the new line and skip over the LF
								crWasSeen = false
							}
							else
							{
								atEOL = true
								break
							}
						}
						else
						{
							crWasSeen = false
							self.lineData.append(byte)
						}
					}
				}
			}
		}

		if lineData.isEmpty
		{
			//	Empty lineData means either an EOF or a blank line.
			if !atEOF
			{
				line = ""	//	Blank line, otherwise line will be nil for EOF
			}
		}
		else
		{
			line = String(bytes: lineData, encoding: encoding)
		}

		return line
	}

	/// Reposition the text file to the begining.
	/// - Returns: void
	public func rewind() -> Void
	{
		if fileHandle != nil
		{
			fileHandle!.seekToFileOffset(0)
			lineIndex = 0
			atEOF = false
		}
	}

	/// Close the file.
	/// - Returns: void
	public func close() -> Void
	{
		if fileHandle != nil
		{
			fileHandle!.closeFile()
			fileHandle = nil
		}
	}
}
