IMPORT $.CPP;

EXPORT StringMatch := MODULE//, FORWARD
    IMPORT Std;

    /***************************************************************************
     * Background:
     *   Currently the ECL Library includes an EDITDistance which uses a Levenshtein
     *   algorithm (limited to the first 255 chars).  This bundle gathers together 
     *   a set of common "approximate string matching" algorithms (including Levenshtein)
     *   which may be more applicable depending on the data domain in question.
     *
     *  Distance Algorithms:
     *   - Hamming
     *   - Levenshtein
     *   - OptimalStringAlignment
     *   - DamerauLevenshtein
     *   - Sift3B
     *
     *  Matching Algorithms (0.0 -> No Match, 1.0->Full Match):
     *   - Jaro
     *   - JaroWinkler
     *
     *  Other:
     *   - LongestCommonSubsequence     
     *   - LongestCommonSubstring
     *    
     * Quick Test/Demo:  
     *   StringMatch.__selfTest.All;
     *    
     **************************************************************************/

    EXPORT Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'StringMatch';
        EXPORT Description := 'Common Algorithms used to measure "Closeness"/"Distance" of strings.';
        EXPORT Authors := ['Gordon Smith'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
        EXPORT DependsOn := [];
        EXPORT Version := '1.0.0';
    END;
    
    /***************************************************************************
     * Distance measuring algorithms.
     **************************************************************************/
    EXPORT Distance := MODULE

        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Hamming_distance">Wikipedia</a> 
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT Hamming(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.Hamming(Str1, Str2);
        END;

        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Levenshtein_distance">Wikipedia</a>
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT Levenshtein(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.Levenshtein(Str1, Str2);
        END;

        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Sequence_alignment">Wikipedia</a>
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT OptimalStringAlignment(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.OptimalStringAlignment(Str1, Str2);
        END;
        
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT DamerauLevenshtein(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.DamerauLevenshtein(Str1, Str2);
        END;
        
        /***************************************************************************
         * @see <a href="http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html">Siderites Blog</a>
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT Sift3B(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.Sift3B(Str1, Str2);
        END;
    END;

    EXPORT Match := MODULE
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance">Wikipedia</a>
         *
         * @param Str1  String 1 for the compare.  
         * @param Str2  String 2 for the compare.  
         *
         * @return      The "Closeness" of the two strings.  
         **************************************************************************/
        EXPORT Jaro(STRING Str1, STRING Str2) := FUNCTION
            RETURN CPP.Jaro(Str1, Str2);
        END;
    
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance">Wikipedia</a>
         *
         * @param Str1          String 1 for the compare.  
         * @param Str2          String 2 for the compare.  
         * @param prefixLegth   Length of prefix to emphasise closeness (Winkler).  
         *
         * @return      The "Closeness" of the two strings.  
         **************************************************************************/
        EXPORT JaroWinkler(STRING Str1, STRING Str2, INTEGER4 prefixLength) := FUNCTION
            RETURN CPP.JaroWinkler(Str1, Str2, prefixLength);
        END;
    END;

    /***************************************************************************
     * @see <a href="http://en.wikipedia.org/wiki/Longest_common_subsequence_problem">Wikipedia</a>
     *
     * @param Str1          String 1 for the compare.  
     * @param Str2          String 2 for the compare.  
     * @param prefixLegth   Length of prefix to emphasise closeness (Winkler).  
     *
     * @return      The "Closeness" of the two strings.  
     **************************************************************************/
    EXPORT LongestCommonSubsequence(STRING Str1, STRING Str2) := FUNCTION
        RETURN CPP.LongestCommonSubsequence(Str1, Str2);
    END;
  
    /***************************************************************************
     * @see <a href="http://en.wikipedia.org/wiki/Longest_common_substring_problem">Wikipedia</a>
     *
     * @param Str1          String 1 for the compare.  
     * @param Str2          String 2 for the compare.  
     **************************************************************************/
    EXPORT LongestCommonSubstring(STRING Str1, STRING Str2) := MODULE
        SHARED ResultSet := CPP.LongestCommonSubstring(Str1, Str2);

        /***************************************************************************
         * @return Longest Common Substring Length.
         **************************************************************************/
        EXPORT ResultLength := ResultSet[1];

        StartPos := ResultSet[2] + 1;
        EndPos := StartPos + ResultLength - 1;

        /***************************************************************************
         * @return Longest Common Substring (String).
         **************************************************************************/
        EXPORT Result := Str1[StartPos..EndPos];
    END;

    EXPORT __selfTest := MODULE
        //  HTML
        testRecord := RECORD
            STRING Str1;
            STRING Str2;
        END;
        testDataset := DATASET([
            {'', ''},
            {'', 'Grodox'},
            {'Gordon', ''},
            {'Gordon', 'Gordon'},
            {'123456', '123'},
            {'123', '123456'},
            {'Gordon', 'Grodox'},
            {'The lazy dog jumped over the fox', 'A lazy fox jumped over the dog'},
            {'This Has', 'No_Common'}
        ], testRecord);
        stringMatchRecord := RECORD
            STRING Str1;
            STRING Str2;
            INTEGER4 hammingDistance;
            INTEGER4 levenshteinDistance;
            INTEGER4 damerauLevenshteinDistance;
            INTEGER4 optimalStringAlignmentDistance;
            REAL4 sift3BDistance;
            REAL4 jaroMatch;
            REAL4 jaroWinklerMatch;
            STRING longestCommonSubsequence;
            RECORD
              INTEGER4 longestCommonSubstringLength;
              STRING longestCommonSubstring;
            END;
        END;

        stringMatchRecord toMatchRecord(testRecord l) := TRANSFORM
            SELF.hammingDistance := Distance.Hamming(l.Str1, l.Str2);
            SELF.levenshteinDistance := Distance.Levenshtein(l.Str1, l.Str2);
            SELF.damerauLevenshteinDistance := Distance.DamerauLevenshtein(l.Str1, l.Str2);
            SELF.optimalStringAlignmentDistance := Distance.OptimalStringAlignment(l.Str1, l.Str2);
            SELF.sift3BDistance := Distance.Sift3B(l.Str1, l.Str2);
            SELF.jaroMatch := Match.Jaro(l.Str1, l.Str2);
            SELF.jaroWinklerMatch := Match.JaroWinkler(l.Str1, l.Str2, 4);
            SELF.longestCommonSubsequence := LongestCommonSubsequence(l.Str1, l.Str2);
            lcs := LongestCommonSubstring(l.Str1, l.Str2);
            SELF.longestCommonSubstringLength := lcs.ResultLength;
            SELF.longestCommonSubstring := lcs.Result;
            SELF := l;
        END;

        EXPORT StringMatchTest := PROJECT(TestDataset, toMatchRecord(left));

        //  All
        EXPORT All := OUTPUT(StringMatchTest, NAMED('StringMatch'));
    END;
END;