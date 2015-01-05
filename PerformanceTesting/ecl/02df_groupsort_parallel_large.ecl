//class=memory
//class=sort
//class=stress

#option ('unlimitedResources', true); // generate all the sorts into a single graph
#option ('resourceMaxActivities', 100000);

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

createSorted(unsigned scale) := FUNCTION
    ds := files.generateSimple(scale); // scale creates unique instances
    gr := GROUP(NOFOLD(ds), id1 DIV scale, LOCAL);
    s := SORT(gr, HASH32(id1));
    RETURN NOFOLD(GROUP(s));
END;

dsAll := createSorted(config.simpleRecordCount DIV 7) +
         createSorted(config.simpleRecordCount DIV 6) + 
         createSorted(config.simpleRecordCount DIV 5) +
         createSorted(config.simpleRecordCount DIV 3);

output(COUNT(NOFOLD(dsAll)) = (config.simpleRecordCount * 4));
