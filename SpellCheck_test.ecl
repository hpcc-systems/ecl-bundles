
// Test! Run (1) and (2) in a builder window. Target one of the Dataland Thors, 
// e.g. thor40_241_7. Then execute (3) against one of the hthor targets.

// 1. Filename. Visible at http://10.241.3.241:8010/
sample_wordlist_from_internet_written_to_Dataland_Thor := '~spellcheck::import::wordlist';

// 2. Build Files.
SpellCheck.fn_build_spellcheck_files(sample_wordlist_from_internet_written_to_Dataland_Thor);

// 3. Use Spellchecker.
strDoc := 'My pheart belongs to nauhgt but her who tolerats me betser than anyone else: my doog.';
chkr := SpellCheck.Checker( strDoc );

OUTPUT( chkr.words_to_check );
OUTPUT( chkr.words_misspelled );
OUTPUT( chkr.all_words );
OUTPUT( chkr.suggestions ); 

// ---------- END ----------
