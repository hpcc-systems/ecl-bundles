import perform.config;
import perform.files;

EXPORT tests := MODULE
    EXPORT join(unsigned expectedMatches) := MODULE
        SHARED dsLeft := files.generateSimpleScaled(0, expectedMatches);
        SHARED dsRight := files.generateSimpleScaled(NOFOLD(0), expectedMatches);

        SHARED numInputRows := config.simpleRecordCount DIV expectedMatches;
        EXPORT numExpected := (numInputRows DIV expectedMatches) * expectedMatches * expectedMatches + (numInputRows % expectedMatches) * (numInputRows % expectedMatches);
        
        EXPORT joinNormal := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches);
        EXPORT joinUnordered := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, UNORDERED);
        EXPORT joinParallel := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, HINT(parallel_match));
        EXPORT joinLookup := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, MANY LOOKUP);
        EXPORT joinHash := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, HASH);
        EXPORT joinSmart := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, SMART);

        EXPORT joinLocalNormal := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, LOCAL);
        EXPORT joinLocalUnordered := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, UNORDERED, LOCAL);
        EXPORT joinLocalParallel := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, HINT(parallel_match), LOCAL);
        EXPORT joinLocalLookup := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, MANY LOOKUP, LOCAL);
        EXPORT joinLocalHash := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, HASH, LOCAL);
        EXPORT joinLocalSmart := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, SMART, LOCAL);
    END;

    EXPORT smartjoin(real scaleNode, real scaleTotal, unsigned expectedMatches) := MODULE
        EXPORT numInputRows := (unsigned8)(config.recordPerNode * scaleNode + config.simpleRecordCount * scaleTotal);
        SHARED dsLeft := files.generateN(0, numInputRows);
        SHARED dsRight := files.generateN(NOFOLD(0), numInputRows);
        EXPORT numExpected := (numInputRows DIV expectedMatches) * expectedMatches * expectedMatches + (numInputRows % expectedMatches) * (numInputRows % expectedMatches);

        EXPORT joinSmartInner := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, SMART, HINT(parallel_match(false)));
        EXPORT joinSmartInnerParallel := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, SMART, HINT(parallel_match));
        EXPORT joinSmartLeftOnly := JOIN(dsLeft, dsRight, (LEFT.id1-1) DIV expectedMatches = (RIGHT.id1-1) DIV expectedMatches, SMART, left only);
    END;
END;
