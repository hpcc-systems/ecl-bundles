//class=memory
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

createSorted(unsigned scale) := FUNCTION
    ds := files.generateSimpleScaled(scale, 4);
    gr := GROUP(NOFOLD(ds), id1 DIV scale,LOCAL);
    s := SORT(gr, HASH32(id1));
    RETURN NOFOLD(GROUP(s));
END;

dsAll := createSorted(5) + createSorted(7) + createSorted(11) + createsorted(13);

output(COUNT(NOFOLD(dsAll)) = (config.simpleRecordCount DIV 4) * 4);
