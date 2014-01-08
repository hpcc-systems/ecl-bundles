import perform.config;
import perform.files;

EXPORT tests := MODULE
    EXPORT join(unsigned expectedMatches) := MODULE
        SHARED dsLeft := files.generateSimpleScaled(0, expectedMatches);
        SHARED dsRight := files.generateSimpleScaled(NOFOLD(0), expectedMatches);
        
        SHARED numInputRecs := config.simpleRecordCount DIV expectedMatches;
        EXPORT numExpected := (numInputRecs DIV expectedMatches) * expectedMatches * expectedMatches + (numInputRecs % expectedMatches) * (numInputRecs % expectedMatches);   
        
        EXPORT joinNormal := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches);
        EXPORT joinUnordered := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, UNORDERED);
        EXPORT joinParallel := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, HINT(parallel_match));
        EXPORT joinLookup := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, MANY LOOKUP);
    END;
END;
