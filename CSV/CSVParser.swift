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
public class CSVParser: NSObject
{
	let csvFile: TextFile
	private var delim: UInt32
	private var delimiter: String
	private var quote: UInt32

	/// The current line number being processed in the CSV file
	public var lineCount = 0

	enum ParserState
	{
		case FIELD_NOT_BEGUN			//	We are currently between fields or at the beginning of the row
		case FIELD_BEGUN				//	We are in a field
		case FIELD_MIGHT_HAVE_ENDED		//	We encountered a double quote inside a quoted field
		case LINE_COMPLETED				//	The line is completely parsed and ready to send to the delegate
		case FIELD_CONTINUES_NEXT_LINE	//	A quoted field contains a new line character.
	}

	private var parserState	= ParserState.FIELD_NOT_BEGUN
	private var parsedLine	= [String]()
	private var parsedField: String = ""

	private var quoted		= false
	private var spaces		= 0

	private let csvTab: UInt32		= 0x09
	private let csvSpace: UInt32	= 0x20


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
	weak public var delegate: CSVParserDelegate?


	/// A CSV reader.
	/// - Parameters:
	///   - delimiter: optional delimeter character, defaults to ","
	///   - quote: optional quote character, defaults to "\"".  A field in a CSV file that contains the delimiter character should be quoted.
	public func startReader(delimiter: String = ",", quote: String = "\"")
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
					if parserState == .LINE_COMPLETED
					{
						d.parserDidReadLine(self, line: parsedLine)

						parsedLine.removeAll(keepCapacity: true)
						parserState = .FIELD_NOT_BEGUN
					}
					else
					if parserState != .FIELD_CONTINUES_NEXT_LINE
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
	public func writer(delimiter: String = ",", quote: String = "\"")
	{
		self.delimiter = delimiter
		self.delim	= (delimiter.unicodeScalars.first?.value)!
		self.quote	= (quote.unicodeScalars.first?.value)!

		//	TODO: CSV writer
	}

	//	used to time the TextFile reader without csv parsing getting in the way
	private func xparse(line: String) -> [String]
	{
		let components = [String]()
		return components
	}


	private func parse(line: String) -> ParserState
	{
//		print( "\n\(line)")

		spaces = 0

		if parserState == .FIELD_CONTINUES_NEXT_LINE
		{
			parsedField.append("\n".unicodeScalars.first!)
			parserState = .FIELD_BEGUN
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
			case .FIELD_NOT_BEGUN:
				if (c == csvTab) && (c != delim)
				{
					//	ignore tab? or handle like space?
					continue
				}
				else
				if (c == csvSpace) && (c != delim)
				{
					//	we don't count the field as "begun" until the first non-space char.
					parsedField.append(ch)
					spaces += 1
				}
				else
				if c == delim
				{
					//	if the first thing we see is a delim then it is an empty field
					parsedLine.append(parsedField)	//	SUBMIT_FIELD
					parsedField.removeAll(keepCapacity: true)

					quoted = false
					spaces = 0
				}
				else
				if c == quote
				{
					//	The field is considered quoted if the first non-white-space character is a quote.
					//	Remove the leading spaces.
					parsedField.removeAll(keepCapacity: true)

					quoted = true
					spaces = 0
					parserState = .FIELD_BEGUN
				}
				else
				{
					//	Our first non-space char - we have begun the field
					parsedField.append(ch)			//	SUBMIT_CHAR
					quoted = false
					spaces = 0
					parserState = .FIELD_BEGUN
				}

			case .FIELD_BEGUN:
				if c == quote
				{
					if quoted
					{
						parsedField.append(ch)		//	SUBMIT_CHAR
						parserState = .FIELD_MIGHT_HAVE_ENDED
					}
					else
					{
						//	double quote inside non-quoted field
						parsedField.append(ch)		//	SUBMIT_CHAR
						parserState = .FIELD_MIGHT_HAVE_ENDED
						spaces = 0
					}
				}
				else
				if c == delim
				{
					//	Delimiter
					if quoted
					{
						parsedField.append(ch)		//	SUBMIT_CHAR
					}
					else
					{
						parsedLine.append(parsedField)	//	SUBMIT_FIELD
						parsedField.removeAll(keepCapacity: true)

						quoted		= false
						spaces		= 0
						parserState	= .FIELD_NOT_BEGUN
					}
				}
				else
				if !quoted && ((c == csvSpace) || (c == csvTab))
				{
					//	Tab or space for non-quoted field

					parsedField.append(ch)			//	SUBMIT_CHAR
					spaces += 1
				}
				else
				{
					parsedField.append(ch)			//	SUBMIT_CHAR
					spaces = 0
				}

			case .FIELD_MIGHT_HAVE_ENDED:
				//	This only happens when the previous character was a quote character and we are in a quoted field.
				if c == delim
				{
					let range = parsedField.endIndex.advancedBy(-(spaces + 1)) ..< parsedField.endIndex
					parsedField.removeRange(range)

					parsedLine.append(parsedField)	//	SUBMIT_FIELD
					parsedField.removeAll(keepCapacity: true)

					quoted		= false
					spaces		= 0
					parserState	= .FIELD_NOT_BEGUN
				}
				else
				if (c == csvSpace) || (c == csvTab)
				{
					parsedField.append(ch)			//	SUBMIT_CHAR
					spaces += 1
				}
				else
				if c == quote
				{
					//	Two quotes in a row
					parserState = .FIELD_BEGUN
				}
				else
				{
					//	Anything else
					parsedField.append(ch)			//	SUBMIT_CHAR
					quoted = false
					spaces = 0
					parserState = .FIELD_BEGUN
				}

			default:
				print("PARSER STATE: \(parserState)")	//	TODO: can this ever happen?
			}
		}

		if parserState == .FIELD_BEGUN
		{
			if quoted
			{
				parserState = .FIELD_CONTINUES_NEXT_LINE
			}
			else
			{
				parsedLine.append(parsedField)
				parsedField.removeAll(keepCapacity: true)

				parserState = .LINE_COMPLETED
				quoted = false
				spaces = 0
			}
		}
		else
		if parserState == .FIELD_MIGHT_HAVE_ENDED
		{
			if !parsedField.isEmpty
			{
				let range = parsedField.endIndex.advancedBy(-(spaces + 1)) ..< parsedField.endIndex
				parsedField.removeRange(range)
				parsedLine.append(parsedField)
				parsedField.removeAll(keepCapacity: true)

				parserState = .LINE_COMPLETED
				quoted = false
				spaces = 0
			}
		}
		else
		if parserState == .FIELD_NOT_BEGUN
		{
			//	We have an empty line or a line of emptyfields.
			parserState = .LINE_COMPLETED
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
	func parserDidStartDocument(parser: CSVParser)

	/// sent when the parser has completed parsing. If this is encountered, the parse was successful.
	func parserDidEndDocument(parser: CSVParser)

	/// sent to the delegate for each line in the CSV document
	/// - Parameters:
	///   - parser: the CSVParser object
	///   - line: an array of strings, one element for each delimited field in the line
	func parserDidReadLine(parser: CSVParser, line: [String])
}
