/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Sequence_alignment">Wikipedia</a>
 *
 * Algorithm ported from <a href="http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance">Wikipedia</a>
 ***********************************************************************************************************************/
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
