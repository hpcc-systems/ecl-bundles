import perform.config;
import perform.files;

EXPORT tests := MODULE
    EXPORT join(unsigned expectedMatches) := MODULE
        SHARED dsLeft := files.generateSimpleScaled(0, expectedMatches);
        SHARED dsRight := files.generateSimpleScaled(NOFOLD(0), expectedMatches);

        SHARED numInputRows := config.simpleRecordCount DIV expectedMatches;
        EXPORT numExpected := (numInputRows DIV expectedMatches) * expectedMatches * expectedMatches + (numInputRows % expectedMatches) * (numInputRows % expectedMatches);
        
        //Add a hash on each side to ensure the input dataset isn't sorted by the id, hopefully won't introduce false positives!
        SHARED test(dsLeft l, dsRight r) := HASH64((l.id1-1) DIV expectedMatches) = HASH64((r.id1-1) DIV expectedMatches);
        SHARED testOrdered(dsLeft l, dsRight r) := (l.id1-1) DIV expectedMatches = (r.id1-1) DIV expectedMatches;
        
        EXPORT joinNormal := JOIN(dsLeft, dsRight, test(LEFT, RIGHT));
        EXPORT joinOrderedInputsNormal := JOIN(dsLeft, dsRight, testOrdered(LEFT, RIGHT)); // inputs happen to be ordered
        EXPORT joinUnordered := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), UNORDERED);
        EXPORT joinParallel := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), HINT(parallel_match));
        EXPORT joinLookup := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), MANY LOOKUP);
        EXPORT joinHash := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), HASH);
        EXPORT joinSmart := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART);

        EXPORT joinLocalNormal := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), LOCAL);
        EXPORT joinLocalUnordered := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), UNORDERED, LOCAL);
        EXPORT joinLocalParallel := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), HINT(parallel_match), LOCAL);
        EXPORT joinLocalLookup := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), MANY LOOKUP, LOCAL);
        EXPORT joinLocalHash := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), HASH, LOCAL);
        EXPORT joinLocalSmart := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART, LOCAL);
    END;

    EXPORT smartjoin(real scaleNode, real scaleTotal, unsigned expectedMatches) := MODULE
        EXPORT numInputRows := (unsigned8)(config.recordPerNode * scaleNode + config.simpleRecordCount * scaleTotal);
        SHARED dsLeft := files.generateN(0, numInputRows);
        SHARED dsRight := files.generateN(NOFOLD(0), numInputRows);
        EXPORT numExpected := (numInputRows DIV expectedMatches) * expectedMatches * expectedMatches + (numInputRows % expectedMatches) * (numInputRows % expectedMatches);

        //Add a hash on each side to ensure the input dataset isn't sorted by the 
        SHARED test(dsLeft l, dsRight r) := HASH64((l.id1-1) DIV expectedMatches) = HASH64((r.id1-1) DIV expectedMatches);
        SHARED testOrdered(dsLeft l, dsRight r) := (l.id1-1) DIV expectedMatches = (r.id1-1) DIV expectedMatches;

        EXPORT joinSmartInner := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART, HINT(parallel_match(false)));
        EXPORT joinSmartInnerParallel := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART, HINT(parallel_match));
        EXPORT joinSmartLeftOnly := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART, left only);

        EXPORT joinLocalOrderedSmartInner := JOIN(SORTED(dsLeft, (id1-1) DIV expectedMatches), dsRight, testOrdered(LEFT, RIGHT), SMART, HINT(parallel_match(false)), LOCAL);
        EXPORT joinLocalUnorderedSmartInner := JOIN(dsLeft, dsRight, test(LEFT, RIGHT), SMART, HINT(parallel_match(false)), LOCAL);
    END;
END;
