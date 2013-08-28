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
