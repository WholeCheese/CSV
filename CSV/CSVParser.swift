//
//  CSVParser.swift
//  CSV
//
//  Created by Allan Hoeltje on 8/3/16.
//  Copyright © 2016 Allan Hoeltje.
//
//	The algorithm employed here in the parse method was gleaned from libcsv by Robert Gamble.
//	Modifications were made to be lenient with quote characters appearing inside of non-quoted
//	fields.
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

/// A class for handling comma-separated-values text files.
/// The value delimiter defaults to "," but can be any other character you like.
open class CSVParser: NSObject
{
	let csvFile: TextFile
	fileprivate var delim: UInt32
	fileprivate var delimiter: String
	fileprivate var quote: UInt32

	/// The current line number being processed in the CSV file
	open var lineCount = 0

	enum ParserState
	{
		case field_NOT_BEGUN			//	We are currently between fields or at the beginning of the row
		case field_BEGUN				//	We are in a field
		case field_MIGHT_HAVE_ENDED		//	We encountered a double quote inside a quoted field
		case line_COMPLETED				//	The line is completely parsed and ready to send to the delegate
		case field_CONTINUES_NEXT_LINE	//	A quoted field contains a new line character.
	}

	fileprivate var parserState	= ParserState.field_NOT_BEGUN
	fileprivate var parsedLine	= [String]()
	fileprivate var parsedField: String = ""

	fileprivate var quoted		= false
	fileprivate var spaces		= 0

	fileprivate let csvTab: UInt32		= 0x09
	fileprivate let csvSpace: UInt32	= 0x20


	/// Initialize the CSV object with a file path.
	/// - Parameters:
	///   - path: an input path for a CSV reader or an output path for a writer.
	///   - delegate: the parser delegate object
	public init(path: String, delegate: CSVParserDelegate)
	{
		self.csvFile = TextFile(path: path)
		self.delegate = delegate

		self.delimiter = ""
		self.delim = 0
		self.quote = 0
	}


	/// delegate management. The delegate is not retained.
	weak open var delegate: CSVParserDelegate?


	/// A CSV reader.
	/// - Parameters:
	///   - delimiter: optional delimeter character, defaults to ","
	///   - quote: optional quote character, defaults to "\"".  A field in a CSV file that contains the delimiter character should be quoted.
	open func startReader(_ delimiter: String = ",", quote: String = "\"")
	{
		self.delimiter = delimiter
		self.delim	= (delimiter.unicodeScalars.first?.value)!
		self.quote	= (quote.unicodeScalars.first?.value)!

		lineCount = 0
		if let d = delegate
		{
			d.parserDidStartDocument(self)

			if let csvStreamReader = self.csvFile.reader()
			{
				var line = csvStreamReader.nextLine()
				while line != nil
				{
					lineCount += 1

					parserState = parse(line!)
					if parserState == .line_COMPLETED
					{
						d.parserDidReadLine(self, line: parsedLine)

						parsedLine.removeAll(keepingCapacity: true)
						parserState = .field_NOT_BEGUN
					}
					else
					if parserState != .field_CONTINUES_NEXT_LINE
					{
						print("ERROR: \(parserState)")	//	TODO: can this ever happen?
						break
					}

					line = csvStreamReader.nextLine()
				}

				csvStreamReader.close()
			}

			d.parserDidEndDocument(self)
		}
	}


	/// A CSV writer.
	/// - Parameters:
	///   - delimiter: optional delimeter character, defaults to ","
	///   - quote: optional quote character, defaults to "\"".  A field in a CSV file that contains the delimiter character should be quoted.
	open func writer(_ delimiter: String = ",", quote: String = "\"")
	{
		self.delimiter = delimiter
		self.delim	= (delimiter.unicodeScalars.first?.value)!
		self.quote	= (quote.unicodeScalars.first?.value)!

		//	TODO: CSV writer
	}

	//	used to time the TextFile reader without csv parsing getting in the way
	fileprivate func xparse(_ line: String) -> [String]
	{
		let components = [String]()
		return components
	}


	fileprivate func parse(_ line: String) -> ParserState
	{
//		print( "\n\(line)")

		spaces = 0

		if parserState == .field_CONTINUES_NEXT_LINE
		{
			parsedField.append(String("\n".unicodeScalars.first!))
			parserState = .field_BEGUN
		}

		for ch in line.unicodeScalars
		{
			let c = ch.value

			//	The spec says this about spaces:
			//		Spaces are considered part of a field and should not be ignored.
			//
			//	But it does not say anything about leading or trailing spaces outside of a quoted field,
			//	for example, for visualization "-" is the space character:
			//
			//		<BOL>---"---first field---"---|---second field---|"---third field---"|---"fourth field"---<EOL>
			//
			//	The parsed fields should be:
			//		|---first field---|
			//		|---second field---|
			//		|---third field---|
			//		|fourth field|
			//
			//	To deal with this we will need to count leading and trailing spaces separately and remove them later
			//	if they are outside of the first/last quote.

			switch parserState
			{
			case .field_NOT_BEGUN:
				if (c == csvTab) && (c != delim)
				{
					//	ignore tab? or handle like space?
					continue
				}
				else
				if (c == csvSpace) && (c != delim)
				{
					//	we don't count the field as "begun" until the first non-space char.
					parsedField.append(String(ch))
					spaces += 1
				}
				else
				if c == delim
				{
					//	if the first thing we see is a delim then it is an empty field
					parsedLine.append(parsedField)	//	SUBMIT_FIELD
					parsedField.removeAll(keepingCapacity: true)

					quoted = false
					spaces = 0
				}
				else
				if c == quote
				{
					//	The field is considered quoted if the first non-white-space character is a quote.
					//	Remove the leading spaces.
					parsedField.removeAll(keepingCapacity: true)

					quoted = true
					spaces = 0
					parserState = .field_BEGUN
				}
				else
				{
					//	Our first non-space char - we have begun the field
					parsedField.append(String(ch))			//	SUBMIT_CHAR
					quoted = false
					spaces = 0
					parserState = .field_BEGUN
				}

			case .field_BEGUN:
				if c == quote
				{
					if quoted
					{
						parsedField.append(String(ch))		//	SUBMIT_CHAR
						parserState = .field_MIGHT_HAVE_ENDED
					}
					else
					{
						//	double quote inside non-quoted field
						parsedField.append(String(ch))		//	SUBMIT_CHAR
						parserState = .field_MIGHT_HAVE_ENDED
						spaces = 0
					}
				}
				else
				if c == delim
				{
					//	Delimiter
					if quoted
					{
						parsedField.append(String(ch))		//	SUBMIT_CHAR
					}
					else
					{
						parsedLine.append(parsedField)	//	SUBMIT_FIELD
						parsedField.removeAll(keepingCapacity: true)

						quoted		= false
						spaces		= 0
						parserState	= .field_NOT_BEGUN
					}
				}
				else
				if !quoted && ((c == csvSpace) || (c == csvTab))
				{
					//	Tab or space for non-quoted field

					parsedField.append(String(ch))			//	SUBMIT_CHAR
					spaces += 1
				}
				else
				{
					parsedField.append(String(ch))			//	SUBMIT_CHAR
					spaces = 0
				}

			case .field_MIGHT_HAVE_ENDED:
				//	This only happens when the previous character was a quote character and we are in a quoted field.
				if c == delim
				{
					let range = parsedField.characters.index(parsedField.endIndex, offsetBy: -(spaces + 1)) ..< parsedField.endIndex
					parsedField.removeSubrange(range)

					parsedLine.append(parsedField)	//	SUBMIT_FIELD
					parsedField.removeAll(keepingCapacity: true)

					quoted		= false
					spaces		= 0
					parserState	= .field_NOT_BEGUN
				}
				else
				if (c == csvSpace) || (c == csvTab)
				{
					parsedField.append(String(ch))			//	SUBMIT_CHAR
					spaces += 1
				}
				else
				if c == quote
				{
					//	Two quotes in a row
					parserState = .field_BEGUN
				}
				else
				{
					//	Anything else
					parsedField.append(String(ch))			//	SUBMIT_CHAR
					quoted = false
					spaces = 0
					parserState = .field_BEGUN
				}

			default:
				print("PARSER STATE: \(parserState)")	//	TODO: can this ever happen?
			}
		}

		if parserState == .field_BEGUN
		{
			if quoted
			{
				parserState = .field_CONTINUES_NEXT_LINE
			}
			else
			{
				parsedLine.append(parsedField)
				parsedField.removeAll(keepingCapacity: true)

				parserState = .line_COMPLETED
				quoted = false
				spaces = 0
			}
		}
		else
		if parserState == .field_MIGHT_HAVE_ENDED
		{
			if !parsedField.isEmpty
			{
				let range = parsedField.characters.index(parsedField.endIndex, offsetBy: -(spaces + 1)) ..< parsedField.endIndex
				parsedField.removeSubrange(range)
				parsedLine.append(parsedField)
				parsedField.removeAll(keepingCapacity: true)

				parserState = .line_COMPLETED
				quoted = false
				spaces = 0
			}
		}
		else
		if parserState == .field_NOT_BEGUN
		{
			//	We have an empty line or a line of emptyfields.
			parserState = .line_COMPLETED
			quoted = false
			spaces = 0
		}
		else
		{
			print("PARSER STATE: \(parserState)")	//	TODO: can this ever happen?
		}

		return parserState
	}
}


/// CSVParser Delegate Protocol
public protocol CSVParserDelegate: NSObjectProtocol
{
	/// sent when the parser begins parsing the document.
	func parserDidStartDocument(_ parser: CSVParser)

	/// sent when the parser has completed parsing. If this is encountered, the parse was successful.
	func parserDidEndDocument(_ parser: CSVParser)

	/// sent to the delegate for each line in the CSV document
	/// - Parameters:
	///   - parser: the CSVParser object
	///   - line: an array of strings, one element for each delimited field in the line
	func parserDidReadLine(_ parser: CSVParser, line: [String])
}
