/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Longest_common_substring_problem">Wikipedia</a>
 *
 * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring">WikiBooks</a>
 ***********************************************************************************************************************/
EXPORT SET OF UNSIGNED INTEGER4 LongestCommonSubstring(STRING s1, STRING s2) := BEGINC++
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
