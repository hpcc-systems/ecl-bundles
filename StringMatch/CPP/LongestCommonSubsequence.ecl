/************************************************************************************************************************
 * @see <a href="http://en.wikipedia.org/wiki/Longest_common_subsequence_problem">Wikipedia</a>
 *
 * Algorithm ported from <a href="http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_subsequence">WikiBooks</a>
 ***********************************************************************************************************************/
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
