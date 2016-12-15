
EXPORT SpellCheck := MODULE,FORWARD  
	IMPORT Std;  
	EXPORT Bundle := MODULE(Std.BundleBase)
		EXPORT Name := 'SpellCheck';
		EXPORT Description := 'An implementation of a spellchecker, and example of ECL bundle layout';
		EXPORT Authors := ['Christopher Albee'];
		EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
		EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
		EXPORT DependsOn := [];
		EXPORT Version := '1.0.0';
  END;

	/*  SpellCheck: high-level documentation
	 *  
	 *  The following program consists of two main components:
	 *
	 *    1.  module Checker: performs spell-checking on a document having type STRING. 
	 *      Params:
	 *          o  STRING strDocument
	 *          o  STRING1 delimiter ( default is a space but allows for other delimiters )
	 *      Exports:
	 *          o  words_to_check   : Dataset of all words provided in the document, sequenced.
	 *          o  words_misspelled : Dataset of all misspelled words in the document.
	 *          o  all_words        : Dataset of all words provided in the document, flagged as 
	 *                                misspelled or not.
	 *          o  suggestions      : Dataset of possible suggested spellings for each mispelled word.
	 *
	 *    2.  function build_spellcheck_files: builds the necessary base files and keyfiles 
	 *    that the Checker module needs to run.
	 *      Params:
	 *          o  STRING import_wordlist_filename ( filename of any wordlist that has been 
	 *          output to a Thor having the record layout layout_word_raw--see below )
	 *	
	 *		3.  module self_test: exercises both the file-building and spell-checking components. Run
	 * 		the exportable attributes in a Builder Window one at a time:
	 * 		  o  SpellCheck.self_test.write_imported_wordlist_to_Thor;
	 * 		  o  SpellCheck.self_test.build_files;
	 * 		  o  OUTPUT( SpellCheck.self_test.spellcheck_results );
	 */
	 
	// ------------------- RECORD LAYOUTS -------------------
	
	SHARED layout_word_raw := { STRING word };
	SHARED layout_word     := { STRING64 word };
	
	SHARED layout_isMisspelled := RECORD
		layout_word_raw;
		BOOLEAN isMisspelled;
	END;
	
	SHARED layout_misspelling_variant := RECORD
		STRING64 variant;
		layout_word;
	END;
	
	SHARED layout_suggestions := RECORD
		STRING misspelling;
		DATASET(layout_word_raw) words;
	END;

	// ------------------- FILE AND KEY DEFINITION ATTRIBUTES -------------------

	SHARED filename_base_wordlist     := '~spellcheck::base::wordlist';	
	SHARED filename_base_misspellings := '~spellcheck::base::misspellings';
	SHARED filename_key_wordlist      := '~spellcheck::key::wordlist';
	SHARED filename_key_misspellings  := '~spellcheck::key::misspellings';
	
	SHARED file_wordlist := 
		DATASET( filename_base_wordlist, layout_word, THOR );

	SHARED file_misspellings := 
		DATASET( filename_base_misspellings, layout_misspelling_variant, THOR );
	
	SHARED key_wordlist := 
		INDEX( file_wordlist, {word}, {file_wordlist}, filename_key_wordlist );

	SHARED key_misspellings := 
		INDEX( file_misspellings, {variant}, {file_misspellings}, filename_key_misspellings );

	// ------------------- UTILITY FUNCTIONS -------------------

	SHARED fn_StringSplit(STRING source, STRING delimiter = ' ') :=
		FUNCTION
			SET OF STRING set_results := STD.Str.SplitWords( source, delimiter );
			RETURN DATASET( set_results, {STRING word} );
		END;

	// ====================== SPELLCHECKER MODULE ======================
		
	EXPORT Checker(STRING strDocument, STRING1 delimiter = ' ') := MODULE
		
		SHARED alphachars_plus_delimiter := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' + delimiter;
		SHARED strDocument_cleaned := STD.Str.Filter( strDocument, alphachars_plus_delimiter );
		
		// Split document string into a dataset of words.
		SHARED ds_words_to_check_pre := fn_StringSplit( strDocument_cleaned, delimiter );
		
		// Project words into STRING64 for faster searching.
		SHARED ds_words_to_check := PROJECT( ds_words_to_check_pre, layout_word );
		
		// Sequence each word so we can return 'all_words' in their original order.
		SHARED ds_words_to_check_seq := 
			PROJECT(
				ds_words_to_check,
				TRANSFORM( {UNSIGNED seq, layout_word},
					SELF.seq := COUNTER,
					SELF.word := LEFT.word
				) );
		
		// Find all misspelled words in the document. Note we didn't do a sort/dedup.
		// This is a bit inefficient and something to improve later.
		SHARED ds_words_misspelled :=
			JOIN(
				ds_words_to_check, key_wordlist,
				KEYED( STD.Str.ToLowerCase(LEFT.word) = RIGHT.word ),
				TRANSFORM(LEFT),
				LEFT ONLY
			);

		// Convert misspelled words to lower case for join against 'variants' key.
		SHARED ds_words_misspelled_toLower :=
			PROJECT(
				ds_words_misspelled, 
				TRANSFORM( layout_word, SELF.word := STD.Str.ToLowerCase(LEFT.word) )
			);
			
		// Join all misspelled words back to the sequenced words and set the misspellings bit.
		SHARED ds_all_words_unsorted := 
			JOIN(
				ds_words_misspelled, ds_words_to_check_seq,
				LEFT.word = RIGHT.word,
				TRANSFORM( {UNSIGNED seq, layout_isMisspelled},
					SELF.seq := RIGHT.seq,
					SELF.word := RIGHT.word,
					SELF.isMisspelled := LEFT.word = RIGHT.word
				),
				RIGHT OUTER
			);
		
		// Sort to reassert the original word order. Slim off the 'seq' field. Recast
		// word as STRING.
		SHARED ds_all_words := 
			PROJECT(
				SORT(ds_all_words_unsorted, seq),
				TRANSFORM( layout_isMisspelled,
					SELF.word := LEFT.word,
					SELF.isMisspelled := LEFT.isMisspelled			
				) );
		
		// Find all spelling suggestions for misspelled words. Make allowance for 
		// a misspelling not finding any suggestions.
		SHARED ds_spelling_suggestions_ungrouped :=
			JOIN(
				ds_words_misspelled_toLower, key_misspellings,
				KEYED(LEFT.word = RIGHT.variant),
				TRANSFORM( layout_misspelling_variant,
					SELF.variant := IF( LEFT.word = RIGHT.variant, RIGHT.variant, LEFT.word ),
					SELF.word := IF( LEFT.word = RIGHT.variant, RIGHT.word, '' )
				),
				LEFT OUTER
			);
		
		// Group and rollup by misspelled word to provide child dataset of suggested 
		// spellings. Recast word as STRING.
		SHARED ds_spelling_suggestions_grouped :=
			GROUP( SORT( ds_spelling_suggestions_ungrouped, variant, word ), variant );
		
		SHARED layout_suggestions doRollup(layout_misspelling_variant le, DATASET(layout_misspelling_variant) allRows) :=
			TRANSFORM
				SELF.misspelling := le.variant;
				SELF.words := PROJECT( allRows, layout_word_raw );
			END;
			
		SHARED ds_spelling_suggestions_unsorted := 
			ROLLUP( ds_spelling_suggestions_grouped, GROUP, doRollup(LEFT, ROWS(LEFT)) );
		
		// Return in same relative order as occurs in strDocument. 
		SHARED ds_spelling_suggestions_with_seq :=
			JOIN(
				ds_words_to_check_seq, ds_spelling_suggestions_unsorted,
				STD.Str.ToLowerCase(LEFT.word) = RIGHT.misspelling,
				TRANSFORM( {UNSIGNED seq, layout_suggestions},
					SELF.seq := LEFT.seq,
					SELF := RIGHT
				),
				INNER
			);
		
		SHARED ds_spelling_suggestions :=
			PROJECT( SORT( ds_spelling_suggestions_with_seq, seq ), layout_suggestions );
			
		// Exportables.
		EXPORT words_to_check   := ds_words_to_check_seq;
		EXPORT words_misspelled := ds_words_misspelled;
		EXPORT all_words        := ds_all_words;
		EXPORT suggestions      := ds_spelling_suggestions;
	END;

	// ====================== DATA FABRICATION FUNCTIONS ======================

	/*  fn_build_file_base_wordlist( ) accepts a string denoting the file name of
	 *  the wordlist to perform data fabrication on. The function presumes no work has 
	 *  been done to clean and standardize the wordlist, so it perfoms the following on
	 *  all records in the wordlist:
	 *    o  casts to lower case
	 *    o  breaks apart any items that are word phrases, e.g. 'au revoir'
	 *    o  removes any non-alpha characters
	 *    o  deduplicates all items
	 *    o  writes the resultant file to Thor as a base file
	 */
	EXPORT fn_build_file_base_wordlist(STRING import_wordlist_filename = '') :=
		FUNCTION
			// Read the imported wordlist from disk and distribute.			
			ds_wordlist      := DATASET( import_wordlist_filename, layout_word_raw, THOR );
			ds_wordlist_dist := DISTRIBUTE( ds_wordlist, HASH32(RANDOM()) );

			// Perform data fabrication to build the wordlist base file.

			// a. Cast to lower case.
			ds_wordlist_toLower :=
				PROJECT(
					ds_wordlist_dist,
					TRANSFORM( layout_word_raw,
					 SELF.word := STD.Str.ToLowerCase(LEFT.word)
					) );
				
			// b. Break apart word phrases.
			ds_wordlist_normalized :=
				PROJECT(
					ds_wordlist_toLower,
					TRANSFORM( {DATASET(layout_word_raw) words},
						SELF.words := fn_StringSplit(LEFT.word)
					) );

			// c. Rollup all word groups...
			ds_wordlist_rolled :=
				ROLLUP(
					ds_wordlist_normalized,
					TRUE,
					TRANSFORM( {DATASET(layout_word_raw) words},
						SELF.words := LEFT.words + RIGHT.words
					),
					LOCAL
				);

			// ...and project out of the child dataset.
			ds_words_all_raw := 
				NORMALIZE( 
					ds_wordlist_rolled,
					COUNT(LEFT.words),
					TRANSFORM( layout_word_raw,
						SELF.word := LEFT.words[COUNTER].word
					) );

			// d. (NOTE: this presumes a non-unicode application) Remove non-alpha chars;
			// assign to string64 for file and index building.
			ds_words_all_alpha_only :=
				PROJECT(
					ds_words_all_raw, 
					TRANSFORM( layout_word,
						SELF.word := STD.Str.Filter( LEFT.word, 'abcdefghijklmnopqrstuvwxyz' )
					) );

			// e. Sort and dedup all words in the wordlist.
			ds_words_deduped := 
				DEDUP(
					SORT(
						DISTRIBUTE( ds_words_all_alpha_only, HASH32(word) ),
						word, LOCAL
					),
					word, LOCAL
				);
					
			// f. Write the wordlist to disk as a base file.
			RETURN OUTPUT( ds_words_deduped, , filename_base_wordlist, OVERWRITE, THOR );
		END;

	/* Each of the following functions--fn_transpose_adjacent_letters( ), fn_omit_letter( ), 
	 * fn_substitute_letter( ), and fn_add_letter( )--generate a type of misspelling variant
	 * and support the function fn_generate_misspelling_variants( ).
	 */
	EXPORT STRING alphachars := 'abcdefghijklmnopqrstuvwxyz';

	EXPORT fn_transpose_adjacent_letters(STRING word, INTEGER c) :=
		FUNCTION	
			str1 := IF( c = 1, '', word[1..(c-1)] );
			str2 := word[c+1] + word[c];
			str3 := IF( LENGTH(word) = c+1, '', word[c+2..] );
			RETURN str1 + str2 + str3;		
		END;
		
	EXPORT fn_omit_letter(STRING word, INTEGER c) :=
		FUNCTION		
			str1 := IF( c = 1, '', word[1..(c-1)] );
			str2 := IF( LENGTH(word) = c, '', word[c+1..] );		
			RETURN str1 + str2;
		END;

	EXPORT fn_substitute_letter(STRING word, INTEGER c) :=
		FUNCTION
			lenAlphachars := LENGTH(alphachars);
			pos    := IF( c % lenAlphachars = 0, (c DIV lenAlphachars), (c DIV lenAlphachars) + 1 );
			letter := IF( c % lenAlphachars = 0, alphachars[lenAlphachars], alphachars[c % lenAlphachars] );
			
			str1 := IF( pos = 1, '', word[1..(pos-1)] );
			str2 := letter;
			str3 := IF( LENGTH(word) = pos, '', word[pos+1..] );
			RETURN str1 + str2 + str3;
		END;

	EXPORT fn_add_letter(STRING word, INTEGER c) :=
		FUNCTION
			lenAlphachars := LENGTH(alphachars);
			pos    := IF( c % lenAlphachars = 0, (c DIV lenAlphachars) - 1, c DIV lenAlphachars );
			letter := IF( c % lenAlphachars = 0, alphachars[lenAlphachars], alphachars[c % lenAlphachars] );
			
			str1 := IF( pos = 0, '', word[1..pos] );
			str2 := letter;
			str3 := IF( LENGTH(word) = pos, '', word[pos+1..] );
			RETURN str1 + str2 + str3;
		END;

	/* The function fn_generate_misspelling_variants( ) generates misspelling variants 
	 * for each word in the wordlist by calling the four functions above. It supports the 
	 * function fn_build_file_base_misspellings( ), below.
	 */
	EXPORT fn_generate_misspelling_variants(STRING wordlist_item) :=
		FUNCTION
			word_trimmed   := TRIM(wordlist_item);
			len_word       := LENGTH(word_trimmed);
			len_alphachars := LENGTH(alphachars);
			ds_single_word := DATASET( [{word_trimmed}], layout_word_raw );
			
			// Generate word variants having a pair of adjacent letters transposed. 
			// Length of word must be at least 2 chars.
			ds_word_variants_1 := 
				NORMALIZE(
					ds_single_word,
					IF( len_word >= 2, len_word-1, 1 ),
					TRANSFORM( layout_misspelling_variant, SKIP( LENGTH(LEFT.word) < 2 ),
						SELF.variant := fn_transpose_adjacent_letters(LEFT.word, COUNTER),
						SELF.word := LEFT.word
					) );			

			// Generate word variants having a letter omitted. Length of word must 
			// be at least 2 chars.
			ds_word_variants_2 := 
				NORMALIZE(
					ds_single_word,
					len_word,
					TRANSFORM( layout_misspelling_variant, SKIP( LENGTH(LEFT.word) < 2 ),
						SELF.variant := fn_omit_letter(LEFT.word, COUNTER),
						SELF.word := LEFT.word
					) );	

			// Generate word variants having a letter substituted.
			ds_word_variants_3 := 
				NORMALIZE(
					ds_single_word,
					len_word * len_alphachars,
					TRANSFORM( layout_misspelling_variant,
						SELF.variant := fn_substitute_letter(LEFT.word, COUNTER),
						SELF.word := LEFT.word
					) );

			// Generate word variants having a letter inserted.
			ds_word_variants_4 := 
				NORMALIZE(
					ds_single_word,
					( len_word + 1) * len_alphachars,
					TRANSFORM( layout_misspelling_variant,
						SELF.variant := fn_add_letter(LEFT.word, COUNTER),
						SELF.word := LEFT.word
					) );

			// Union all variants; filter out the correctly-spelled words; sort and dedup.
			ds_variants_all := 
					ds_word_variants_1 + ds_word_variants_2 + ds_word_variants_3 + ds_word_variants_4;
			
			ds_variants_filtered := ds_variants_all(variant != wordlist_item);	
			ds_variants_deduped  := DEDUP(SORT(ds_variants_filtered, variant), variant);

			RETURN ds_variants_deduped;
		END;
	
	/*  The function fn_build_file_base_misspellings( ) generates a base file on Thor
	 *  that contains misspelling variants for each of the items in the base file named
	 *  '~spellcheck::base::wordlist' (see above). As such, it presumes that the function
	 *  fn_build_file_base_wordlist( ) completed successfully. To generate misspelling variants,
	 *  this function calls fn_generate_misspelling_variants( ), which in turn calls these:
	 *    o  fn_transpose_adjacent_letters( )
	 *    o  fn_omit_letter( )
	 *    o  fn_substitute_letter( )
	 *    o  fn_add_letter( )
	 *  Finally, this function writes the resultant dataset to Thor as a base file.
	 */
	EXPORT fn_build_file_base_misspellings() :=
		FUNCTION
			// a. Read in the Distributed wordlist file.
			ds_wordslist_dist := DISTRIBUTED( file_wordlist(LENGTH(TRIM(word)) > 0), HASH32(word) );

			// b. Obtain misspelling variants for each word in the wordlist.
			ds_misspelling_variants :=
				PROJECT(
					ds_wordslist_dist,
					TRANSFORM( {DATASET(layout_misspelling_variant) misspellings},
						SELF.misspellings := fn_generate_misspelling_variants( LEFT.word )
					) );

			// c. Roll up the misspelling variants.
			ds_misspelling_variants_rolled := 
				ROLLUP(
					ds_misspelling_variants,
					TRUE,
					TRANSFORM( {DATASET(layout_misspelling_variant) misspellings},
						SELF.misspellings := LEFT.misspellings + RIGHT.misspellings
					),
					LOCAL
				);

			// d. Normalize into a flat, two-field dataset.
			ds_misspelling_variants_flat :=
				NORMALIZE( 
					ds_misspelling_variants_rolled, 
					LEFT.misspellings,
					TRANSFORM( layout_misspelling_variant,
						SELF.variant := RIGHT.variant,
						SELF.word    := RIGHT.word
					) );

			// e. Sort...
			ds_misspelling_variants_sorted := 
					SORT( ds_misspelling_variants_flat, variant, word, LOCAL );

			// f. ..and write to disk as a base file.
			RETURN OUTPUT( ds_misspelling_variants_sorted, , filename_base_misspellings, OVERWRITE, THOR );
		END;
	
	/*  The following function is the main process for generating the base files and 
	 *  keyfiles needed to run the SpellCheck program. It accepts a string denoting the 
	 *  file name of any wordlist that has been output to a Thor having the record layout 
	 *  layout_word_raw (see definition above).
	 */
	EXPORT build_spellcheck_files(STRING import_wordlist_filename = '') :=
		FUNCTION
			IF( import_wordlist_filename = '', FAIL('Please provide the file name of the wordlist you wish to import.') );
			RETURN SEQUENTIAL(
					fn_build_file_base_wordlist(import_wordlist_filename),
					fn_build_file_base_misspellings(),
					BUILD(key_wordlist),
					BUILD(key_misspellings)					
				);
		END;
	
	EXPORT self_test := MODULE
	
		SHARED filename_import_wordlist := '~spellcheck::import::wordlist_misspelled_cities';
		
		SHARED imported_wordlist :=
			DATASET(
				[ // Most misspelled cities in America.
					{'Pittsburgh'},{'Tucson'},{'Cincinnati'},{'Albuquerque'},{'Culpeper'},
					{'Asheville'},{'Worcester'},{'Manhattan'},{'Phoenix'},{'Niagara Falls'},
					{'Fredericksburg'},{'Philadelphia'},{'Detroit'},{'Chattanooga'},{'Gloucester'}
				],
				{ STRING word }
			);

		SHARED strDoc := // ----------------------->    correct    transp.  subst.  omission      addition
			'My childhood was spent living variously in Albuquerque, Tuscon, Pheenix, Ashville and Culpepper.';

		// 1. Write a sample wordlist to Thor. 
		EXPORT write_imported_wordlist_to_Thor := 
				OUTPUT( imported_wordlist, , filename_import_wordlist, OVERWRITE, THOR );
		
		// 2. Build Files. 
		EXPORT build_files := build_spellcheck_files(filename_import_wordlist);

		// 3. Use Spellchecker. 
		EXPORT spellcheck_results := SpellCheck.Checker( strDoc );
  END;
END;
