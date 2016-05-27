//class=index
//class=indexwrite
//class=setup

import $.^ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := DATASET(config.simpleRecordCount * config.indexScale, format.createSimple(COUNTER), DISTRIBUTED);

i:= INDEX(ds,{ 
    unsigned1 id1a := id1 >> 56;
    unsigned1 id1b := id1 >> 48;
    unsigned1 id1c := id1 >> 40;
    unsigned1 id1d := id1 >> 32;
    unsigned1 id1e := id1 >> 24;
    unsigned1 id1f := id1 >> 16;
    unsigned1 id1g := id1 >> 8;
    unsigned1 id1h := id1 >> 0;
    id2, id3 }, { id4 }, files.indexName+'_id1xid2id3id4');
    
BUILDINDEX(i, OVERWRITE);
