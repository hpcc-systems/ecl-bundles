//class=memory
//class=parallel
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
#option ('unlimitedResources', true); // generate all the sorts into a single graph

s(unsigned delta) := FUNCTION
    ds := files.generateSimpleScaled(delta, 4);

    RETURN NOFOLD(sort(ds, id3, local));
END;

ds(unsigned i) := s(i+0x00000000) + s(i+0x10000000) + s(i+0x20000000) + s(i+0x30000000);

dsAll := ds(0);

output(COUNT(NOFOLD(dsAll)) = (config.simpleRecordCount DIV 4) * 4);
