# CSV
CSV - a fast cvs parser for large files written in Swift

Yet another CSV parser.  This one is written in Swift and is meant for processing very large input files. I was able to read and parse a 10 million line file in around 52 to 58 seconds.  Includes a few basic cvs files for unit testing.  Thoroughly tested and has no memory leaks.

The algorithm employed here in the parse method was gleaned from libcsv by Robert Gamble.

Enjoy!
-Allan
