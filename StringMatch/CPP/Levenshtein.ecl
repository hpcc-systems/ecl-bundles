/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Levenshtein_distance">Wikipedia</a>
 *
 * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance">WikiBooks</a>
 ***********************************************************************************************************************/
EXPORT UNSIGNED INTEGER4 Levenshtein(STRING s1, STRING s2) := BEGINC++
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
