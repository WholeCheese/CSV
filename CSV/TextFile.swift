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
open class TextFile
{
	var path: String
	var encoding: String.Encoding

	/// Initializes a text file from a path using NSUTF8StringEncoding.
	///
	/// - Parameter path: The path to be created a text file from.
	public init(path: String)
	{
		self.encoding = String.Encoding.utf8
		self.path = path
	}

	/// Initializes a text file from a path with an encoding.
	///
	/// - Parameter path: The path to be created a text file from.
	/// - Parameter encoding: The encoding to be used for the text file.
	public init(path: String, encoding: String.Encoding)
	{
		self.encoding = encoding
		self.path = path
	}

	/// Initializes a text file reader.
	///
	/// - Parameter bufferSize: The byte size of the read buffer.  Defaults to 4096 bytes.
	/// - Returns: A text file StreamReader.
	open func reader(_ bufferSize: Int = 4096) -> StreamReader?
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
open class StreamReader
{
	var fileHandle: FileHandle?
	var atEOF: Bool = false
	let encoding: String.Encoding
	let bufferSize: Int
	var lineData: [UInt8]
	var lineIndex = 0
	var tmpData = Data()
	var buffer = Data()
	var beginByte = 0
	let crDelim: UInt8 = 13		//	0x0D "\r"
	let lfDelim: UInt8 = 10		//	0x0A "\n"
	var crWasSeen = false

	init?(
		path: String,
		encoding: String.Encoding = String.Encoding.utf8,
		bufferSize: Int = 4096
		)
	{
		self.bufferSize = bufferSize
		self.encoding = encoding
		self.lineData = [UInt8](repeating: 0, count: bufferSize)
		self.lineData.removeAll(keepingCapacity: true)

		do
		{
			let fileURL = URL(fileURLWithPath: path)

			self.fileHandle = try FileHandle(forReadingFrom: fileURL)
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
			//	TODO: make this a bit more robust?
			let error = e as NSError

			print("localizedDescription: \(error.localizedDescription)")
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
	open func nextLine() -> String?
	{
		var line: String?

		if fileHandle != nil
		{
			var atEOL: Bool = false

			lineData.removeAll(keepingCapacity: true)

			while !atEOF
			{
				if atEOL
				{
					break
				}
				else
				{
					if beginByte == buffer.count
					{
						beginByte = 0

						buffer = fileHandle!.readData( ofLength: bufferSize )
						if buffer.isEmpty
						{
							atEOF = true
							break
						}
					}

					buffer.withUnsafeBytes
					{
						(uPtr: UnsafePointer<UInt8>) in
						var ptr = uPtr
						for _ in 0..<buffer.count
						{
							let byte = ptr.pointee

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

							ptr = ptr.advanced(by: 1)
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
	open func rewind() -> Void
	{
		if fileHandle != nil
		{
			fileHandle!.seek(toFileOffset: 0)
			lineIndex = 0
			atEOF = false
		}
	}

	/// Close the file.
	/// - Returns: void
	open func close() -> Void
	{
		if fileHandle != nil
		{
			fileHandle!.closeFile()
			fileHandle = nil
		}
	}
}
