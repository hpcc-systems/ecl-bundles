/************************************************************************************************************************
 * @see <a href="http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html">Siderites Blog</a>
 *
 * Algorithm ported from <a href="http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html">Siderites Blog</a>
 ***********************************************************************************************************************/
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
