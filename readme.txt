
Given cipher text, the following ECL code decrpyts the longest length word. 
Once the longest word has been discovered, the resulting letter can be used for the rest of the text

One very fast trick is to find a word that is greater than six
characters and determine it's pattern. For each unique letter in the word it is assigned a
sequential number. Example cipher text QWRGTRYTRQT = CONVENIENCE
                                       12345365315   12345365315


Dictionary File : The dictionary file needs to be sprayed as a CSV file and be given the name
                  ~thor::in::dictionary  terminator('\n')
					 separator(',')
					 quote('')
