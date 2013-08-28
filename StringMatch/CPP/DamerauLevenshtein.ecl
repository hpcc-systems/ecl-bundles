/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
 *
 * Algorithm ported from <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
 ***********************************************************************************************************************/
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
