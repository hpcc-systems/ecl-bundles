/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance">Wikipedia</a>
 *
 * Algorithm ported from <a href="https://github.com/NaturalNode/natural/blob/master/lib/natural/distance/jaro-winkler_distance.js">Natural Node</a>
 ***********************************************************************************************************************/
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

EXPORT REAL4 JaroWinkler(STRING s1, STRING s2, INTEGER4 prefixlength) := FUNCTION
  REAL4 jaroDistance := $.Jaro(s1, s2);
  RETURN Winkler(s1, s2, jaroDistance, prefixLength);
END; 
