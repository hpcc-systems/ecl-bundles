//class=memory
//class=sort

#option ('unlimitedResources', true); // generate all the sorts into a single graph
#option ('resourceMaxActivities', 100000);

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

createSorted(unsigned scale) := FUNCTION
    ds := files.generateSimpleScaled(scale, 16);
    gr := GROUP(NOFOLD(ds), id1 DIV scale,LOCAL);
    s := SORT(gr, HASH32(id1));
    RETURN NOFOLD(GROUP(s));
END;

dsAll := createSorted(1) +
         createSorted(2) + 
         createSorted(3) +
         createSorted(5) +
         createSorted(7) +
         createSorted(11) +
         createSorted(13) +
         createSorted(17) +
         createSorted(19) +
         createSorted(23) +
         createSorted(29) +
         createSorted(31) +
         createSorted(37) +
         createSorted(41) +
         createSorted(43) +
         createsorted(47);

output(COUNT(NOFOLD(dsAll)) = (config.simpleRecordCount DIV 16) * 16);
