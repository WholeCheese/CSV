# CSV
CSV - a fast cvs parser for large files written in Swift

Yet another CSV parser.  This one is written in Swift and is meant for processing very large input files. I was able to read and parse a 10 million line file in around 52 to 58 seconds.  Includes a few basic cvs files for unit testing.  Thoroughly tested and has no memory leaks.

The algorithm employed in the CSV parser was gleaned from libcsv by Robert Gamble.
Modifications were made to be lenient with quote characters appearing inside of non-quoted fields.

Updated on August 9, 2016
1) Added support for quoted fields containing new-line characters.
2) Made the parser more lenient towards quote characters within non-quoted fields.
3) General code cleanup.

TODO:
1) Add a CSV writer
2) Make the XCTest more robust and check the expected values.
3) Make the TextFile more robust and verify that the file is a text file and not some bunch of binary data.


Enjoy!
-Allan
