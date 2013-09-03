EXPORT StringMatch := MODULE, FORWARD
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
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT UNSIGNED INTEGER4 Hamming(STRING s1, STRING s2) := BEGINC++
        #option pure
            #include <algorithm>
        #body
            if(lenS1 == 0 && lenS2 == 0) {
                return 0;
            } else if (lenS1 == 0) {
                return lenS2;
            } else if (lenS2 == 0) {
                return lenS1;
            }

            unsigned int dist = abs((int)(lenS1 - lenS2));
            unsigned int len = std::min(lenS1, lenS2);
            for (unsigned int i = 0; i < len; ++i) {
                if (s1[i] != s2[i]) {
                    ++dist;
                }
            }
            return dist;
        ENDC++;

        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Levenshtein_distance">Wikipedia</a>
         *
         * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance">WikiBooks</a>
         *
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT INTEGER4 Levenshtein(STRING s1, STRING s2) := BEGINC++
        #option pure
            #define Levenshtein_MIN3(a, b, c) ((a) < (b) ? ((a) < (c) ? (a) : (c)) : ((b) < (c) ? (b) : (c)))
        #body
            if(lenS1 == 0 && lenS2 == 0) {
                return 0;
            } else if (lenS1 == 0) {
                return lenS2;
            } else if (lenS2 == 0) {
                return lenS1;
            }

            unsigned int* column = new unsigned int[lenS1 + 1];
            for (int y = 1; y <= lenS1; y++)
                column[y] = y;

            unsigned int lastdiag, olddiag;
            for (int x = 1; x <= lenS2; x++) {
                column[0] = x;
                for (int y = 1, lastdiag = x-1; y <= lenS1; y++) {
                    olddiag = column[y];
                    column[y] = Levenshtein_MIN3(column[y] + 1, column[y - 1] + 1, lastdiag + (s1[y - 1] == s2[x - 1] ? 0 : 1));
                    lastdiag = olddiag;
                }
            }

            int retVal = column[lenS1];
            delete[] column;
            return(retVal);
        ENDC++;

        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Sequence_alignment">Wikipedia</a>
         *
         * Algorithm ported from <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
         *
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT UNSIGNED INTEGER4 OptimalStringAlignment(STRING s1, STRING s2) := BEGINC++
        #option pure
            #include <vector>
            namespace ns_OptimalStringAlignment {
                typedef std::vector<unsigned int> uiVector;
                typedef std::vector<uiVector> uiVectorVector;
            }
        #body
            if(lenS1 == 0 && lenS2 == 0) {
                return 0;
            } else if (lenS1 == 0) {
                return lenS2;
            } else if (lenS2 == 0) {
                return lenS1;
            }

            ns_OptimalStringAlignment::uiVectorVector d(lenS1 + 1);   
            for (unsigned int i = 0; i <= lenS1; ++i) {
                d[i].resize(lenS2 + 1);
                d[i][0] = i;
            }
            for (unsigned int j = 0; j <= lenS2; ++j) {
                d[0][j] = j;
            }

            unsigned int cost = 0;
            for (unsigned int j = 1; j <= lenS2; j++) {
                for (unsigned int i = 1; i <= lenS1; i++) {
                    cost = (s1[i-1] == s2[j-1]) ? 0 : 1;
                    d[i][j] = std::min(d[i][j-1] + 1, std::min(d[i-1][j] + 1, d[i-1][j-1] + cost));
                    if(i > 1 && j > 1 && s1[i-1] == s2[j-2] && s1[i-2] == s2[j-1]) {
                        d[i][j] = std::min(d[i][j], d[i-2][j-2] + cost);
                    }
                }
            }
            return d[lenS1][lenS2];
        ENDC++;
        
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
         *
         * Algorithm ported from <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
         *
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT UNSIGNED INTEGER4 DamerauLevenshtein(STRING s1, STRING s2) := BEGINC++
        #option pure
            #include <vector>
            #include <map>
            namespace DLD {
                typedef std::map<char, int> ciMap;
                typedef std::vector<unsigned int> uiVector;
                typedef std::vector<uiVector> uiVectorVector;
            }
        #body
            if(lenS1 == 0 && lenS2 == 0) {
                return 0;
            } else if (lenS1 == 0) {
                return lenS2;
            } else if (lenS2 == 0) {
                return lenS1;
            }
            DLD::ciMap charDictionary;
            DLD::uiVectorVector d(lenS1 + 1);
            for (unsigned int i = 0; i <= lenS1; i++) {
                d[i].resize(lenS2 + 1);
                d[i][0] = i;
            }
            for (unsigned int j = 0; j <= lenS2; j++) {
                d[0][j] = j;
            }
            for (unsigned int i = 0; i < lenS1; i++) {
                charDictionary[s1[i]] = 0;
            }
            for (unsigned int j = 0; j < lenS2; j++) {
                charDictionary[s2[j]] = 0;
            }
            for (unsigned int i = 1; i <= lenS1; i++) {
                unsigned int db = 0;
                for (unsigned int j = 1; j <= lenS2; j++) {
                    unsigned int i1 = charDictionary[s2[j-1]];
                    unsigned int j1 = db;
                    unsigned int cost = 0;
                    if (s1[i-1] == s2[j-1]) {
                        db = j;
                    } else {
                        cost = 1;
                    }
                    d[i][j] = std::min(d[i][j-1] + 1, std::min(d[i-1][j] + 1, d[i-1][j-1] + cost));
                    if(i1 > 0 && j1 > 0) {
                        d[i][j] = std::min(d[i][j], d[i1-1][j1-1] + (i-i1-1) + (j-j1-1) + 1);
                    }
                }
                charDictionary[s1[i-1]] = i;
            }
            return d[lenS1][lenS2];
        ENDC++;
        
        /***************************************************************************
         * @see <a href="http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html">Siderites Blog</a>
         *
         * Algorithm ported from <a href="http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html">Siderites Blog</a>
         *
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Distance" of the two strings.  
         **************************************************************************/
        EXPORT REAL4 Sift3B(STRING s1, STRING s2) := BEGINC++
        #option pure
            namespace ns_Sift3B {
                float roundf(float value) {
                    return floor(value + 0.5);
                }
            }
        #body
            if(lenS1 == 0 && lenS2 == 0) {
                return 0;
            } else if (lenS1 == 0) {
                return lenS2;
            } else if (lenS2 == 0) {
                return lenS1;
            }
            unsigned int c1 = 0;
            unsigned int c2 = 0;
            unsigned int lcs = 0;
            unsigned int temporaryDistance = 0;
            unsigned int maxOffset = 5;

            while ((c1 < lenS1) && (c2 < lenS2)) {
                if (s1[c1] == s2[c2]) {
                    lcs++;
                } else {
                    if (c1<c2) {
                        c2=c1;
                    } else {
                        c1=c2;
                    }
                    for (unsigned int i = 0; i < maxOffset; i++) {
                        if ((c1 + i < lenS1) && (s1[c1 + i] == s2[c2])) {
                            c1+= i;
                            break;
                        }
                        if ((c2 + i < lenS2) && (s1[c1] == s2[c2 + i])) {
                            c2+= i;
                            break;
                        }
                    }
                }
                c1++;
                c2++;
            }
            return ns_Sift3B::roundf((lenS1 + lenS2) / 1.5 - lcs);
        ENDC++;
    END;

    EXPORT Match := MODULE
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance">Wikipedia</a>
         *
         * Algorithm ported from <a href="https://github.com/NaturalNode/natural/blob/master/lib/natural/distance/jaro-winkler_distance.js">Natural Node</a>
         *
         * @param s1    String 1 for the compare.  
         * @param s2    String 2 for the compare.  
         *
         * @return      The "Closeness" of the two strings.  
         **************************************************************************/
        EXPORT REAL4 Jaro(STRING s1, STRING s2) := BEGINC++
        #option pure
            #include <algorithm>
            #include <vector>
            namespace ns_Jaro {
                typedef std::vector<bool> boolVector;
            }
        #body    
            if(lenS1 == 0 && lenS2 == 0) {
                return 1.0;
            } else if (lenS1 == 0) {
                return 0.0;
            } else if (lenS2 == 0) {
                return 0.0;
            }

            unsigned int matchWindow = floor(std::max(lenS1, lenS2) / 2.0) - 1;
            ns_Jaro::boolVector matches1(lenS1);
            ns_Jaro::boolVector matches2(lenS2);
            unsigned int m = 0;
            float t = 0;
            for (unsigned int i = 0; i < lenS1; ++i) {
                bool matched = false;

                // check for an exact match
                if (s1[i] == s2[i]) {
                    matches1[i] = true;
                    matches2[i] = true;
                    matched = true;
                    ++m;
                } else {
                    for (unsigned int k = (i <= matchWindow) ? 0 : i - matchWindow; (k <= i + matchWindow) && k < lenS2 && !matched; ++k) {
                        if (s1[i] == s2[k]) {
                            if(!matches1[i] && !matches2[k]) {
                                ++m;
                            }

                            matches1[i] = matches2[k] = matched = true;
                        }
                    }
                }
            }
            if(m == 0)
                return 666.0;

            unsigned int k = 0;
            for (unsigned int i = 0; i < lenS1; ++i) {
                if ( matches1[k] ) {
                    while(k < matches2.size() && !matches2[k]) {
                        k++;
                    }
                    if (k < matches2.size() && s1[i] != s2[k]) {
                        t++;
                    }

                    k++;
                }
            }
            
            t = t / 2.0;
            return ((float)m / (float)lenS1 + (float)m / (float)lenS2 + ((float)m - t) / (float)m) / 3;
        ENDC++;
    
        /***************************************************************************
         * @see <a href="http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance">Wikipedia</a>
         *
         * Algorithm ported from <a href="https://github.com/NaturalNode/natural/blob/master/lib/natural/distance/jaro-winkler_distance.js">Natural Node</a>
         *
         * @param s1          String 1 for the compare.  
         * @param s2          String 2 for the compare.  
         * @param prefixLegth   Length of prefix to emphasise closeness (Winkler).  
         *
         * @return      The "Closeness" of the two strings.  
         **************************************************************************/
        EXPORT JaroWinkler(STRING s1, STRING s2, INTEGER4 prefixLength) := FUNCTION
            REAL4 Winkler(STRING s1, STRING s2, REAL4 jaro, INTEGER4 prefixlength) := BEGINC++
            #option pure
                #include <algorithm>
            #body
                if(lenS1 == 0 && lenS2 == 0) {
                    return 1.0;
                } else if (lenS1 == 0) {
                    return 0.0;
                } else if (lenS2 == 0) {
                    return 0.0;
                }

                unsigned int l = 0;
                while(l < prefixlength && l < lenS1  && l < lenS2 && s1[l] == s2[l]) {
                    l++;
                }

                const static float p = 0.1;
                return jaro + (float)l * p * (1.0 - jaro);
            ENDC++;

            REAL4 jaroDistance := Jaro(s1, s2);
              RETURN Winkler(s1, s2, jaroDistance, prefixLength);
        END;
    END;

    /***************************************************************************
     * @see <a href="http://en.wikipedia.org/wiki/Longest_common_subsequence_problem">Wikipedia</a>
     *
     * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_subsequence">WikiBooks</a>
     *
     * @param s1          String 1 for the compare.  
     * @param s2          String 2 for the compare.  
     * @param prefixLegth   Length of prefix to emphasise closeness (Winkler).  
     *
     * @return      The "Closeness" of the two strings.  
     **************************************************************************/
    EXPORT STRING LongestCommonSubsequence(STRING s1, STRING s2) := BEGINC++
    #option pure
        #include <vector>

        class LongestCommonSubsequenceClass {
            class LCSTable {
                size_t   m_;
                size_t   n_;
                size_t*  data_;

            public:
                LCSTable(size_t m, size_t n) : m_(m), n_(n) {
                    data_ = new size_t[(m_ + 1) * (n_ + 1)];
                }
                ~LCSTable() {
                    delete [] data_;
                }

                void setAt(size_t i, size_t j, size_t value) {
                    data_[i + j * (m_ + 1)] = value;
                }

                size_t getAt(size_t i, size_t j) const {
                    return data_[i + j * (m_ + 1)];
                }

                template<typename T> void build(const T* X, const T* Y) {
                    for (size_t i=0; i<=m_; ++i)
                        setAt(i, 0, 0);

                    for (size_t j=0; j<=n_; ++j)
                        setAt(0, j, 0);

                    for (size_t i = 0; i < m_; ++i) {
                        for (size_t j = 0; j < n_; ++j) {
                            if (X[i] == Y[j])
                                setAt(i+1, j+1, getAt(i, j)+1);
                            else
                                setAt(i+1, j+1, std::max(getAt(i+1, j), getAt(i, j+1)));
                        }
                    }
                }
            };

            template<typename T> static void backtrackOne(const LCSTable& table, const T* X, const T* Y, size_t i, size_t j, std::vector<T>& result) {
                if (i == 0 || j == 0)
                    return;
                if (X[i - 1] == Y[j - 1]) {
                    backtrackOne(table, X, Y, i - 1, j - 1, result);
                    result.push_back(X[i - 1]);
                    return;
                }
                if (table.getAt(i, j - 1) > table.getAt(i -1, j))
                    backtrackOne(table, X, Y, i, j - 1, result);
                else
                    backtrackOne(table, X, Y, i - 1, j, result);
            }

        public:
            template<typename T> static void findOne(const T* X, size_t m, const T* Y, size_t n, std::vector<T>& result) {
                LCSTable table(m, n);
                table.build(X, Y);
                backtrackOne(table, X, Y, m, n, result);
            }
        };  
    #body
        if(lenS1 == 0 || lenS2 == 0) {
            __lenResult = 0;
            __result = NULL;
            return;
        }
        std::vector<char> result;
        LongestCommonSubsequenceClass::findOne<char>(s1, lenS1, s2, lenS2, result);
        __lenResult = result.size();
        __result = (char *)rtlMalloc(__lenResult);
        strncpy(__result, &result[0], __lenResult); 
    ENDC++;
  
    /***************************************************************************
     * @see <a href="http://en.wikipedia.org/wiki/Longest_common_substring_problem">Wikipedia</a>
     *
     * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring">WikiBooks</a>
     *
     * @param s1          String 1 for the compare.  
     * @param s2          String 2 for the compare.  
     **************************************************************************/
    EXPORT LongestCommonSubstring(STRING s1, STRING s2) := MODULE
        SET OF UNSIGNED INTEGER4 LongestCommonSubstring(STRING s1, STRING s2) := BEGINC++
            if(lenS1 == 0 || lenS2 == 0) {
                __isAllResult = false;
                __lenResult = 0;
                __result = NULL;
                return;
            }

            int *curr = new int [lenS2];
            int *prev = new int [lenS2];
            int *swap = NULL;
            int maxSubstr = 0;
            int lastSubsBegin = 0;
            for(int i = 0; i < lenS1; ++i) {
                for(int j = 0; j < lenS2; ++j) {
                     if(s1[i] != s2[j]) {
                         curr[j] = 0;
                     } else {
                         if(i == 0 || j == 0) {
                             curr[j] = 1;
                         } else {
                             curr[j] = 1 + prev[j-1];
                         }
                         if(maxSubstr < curr[j]) {
                             maxSubstr = curr[j];
                             int thisSubsBegin = i - curr[j] + 1;
                             if (lastSubsBegin != thisSubsBegin) {
                                 lastSubsBegin = thisSubsBegin;
                             }
                         }
                     }
                }
                swap=curr;
                curr=prev;
                prev=swap;
            }

            delete [] curr;
            delete [] prev;
            __isAllResult = false;
            __lenResult = 2 * sizeof(size32_t);
            __result = rtlMalloc(__lenResult);
            size32_t * cur = (size32_t *)__result;
            *cur = maxSubstr;
            *(++cur) = lastSubsBegin;
        ENDC++;

        SHARED ResultSet := LongestCommonSubstring(s1, s2);

        /***************************************************************************
         * @return Longest Common Substring Length.
         **************************************************************************/
        EXPORT ResultLength := ResultSet[1];

        StartPos := ResultSet[2] + 1;
        EndPos := StartPos + ResultLength - 1;

        /***************************************************************************
         * @return Longest Common Substring (String).
         **************************************************************************/
        EXPORT Result := s1[StartPos..EndPos];
    END;

    EXPORT __selfTest := MODULE
        //  HTML
        testRecord := RECORD
            STRING s1;
            STRING s2;
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
            STRING s1;
            STRING s2;
            INTEGER4 hammingDistance;
            INTEGER4 levenshteinDistance;
            INTEGER4 damerauLevenshteinDistance;
            INTEGER4 optimalStringAlignmentDistance;
            REAL4 sift3BDistance;
            REAL4 jaroMatch;
            REAL4 jaroWinklerMatch;
            STRING longestCommonSubsequence;
            INTEGER4 longestCommonSubstringLength;
            STRING longestCommonSubstring;
        END;

        stringMatchRecord toMatchRecord(testRecord l) := TRANSFORM
            SELF.hammingDistance := Distance.Hamming(l.s1, l.s2);
            SELF.levenshteinDistance := Distance.Levenshtein(l.s1, l.s2);
            SELF.damerauLevenshteinDistance := Distance.DamerauLevenshtein(l.s1, l.s2);
            SELF.optimalStringAlignmentDistance := Distance.OptimalStringAlignment(l.s1, l.s2);
            SELF.sift3BDistance := Distance.Sift3B(l.s1, l.s2);
            SELF.jaroMatch := Match.Jaro(l.s1, l.s2);
            SELF.jaroWinklerMatch := Match.JaroWinkler(l.s1, l.s2, 4);
            SELF.longestCommonSubsequence := LongestCommonSubsequence(l.s1, l.s2);
            lcs := LongestCommonSubstring(l.s1, l.s2);
            SELF.longestCommonSubstringLength := lcs.ResultLength;
            SELF.longestCommonSubstring := lcs.Result;
            SELF := l;
        END;

        EXPORT StringMatchTest := PROJECT(TestDataset, toMatchRecord(left));

        //  All
        EXPORT All := OUTPUT(StringMatchTest, NAMED('StringMatch'));
    END;
END;