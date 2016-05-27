//class=index
//class=indexread

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;

//Stepped index read
ds := SORTED(STEPPED(files.manyIndex123(
            id1a = 0 AND 
            id1b = 0 AND 
            id1c = 0 AND 
            id1d = 0 AND 
            id1e = 0 AND 
            id1f IN [1,3]), id2), id2, ASSERT);
             
cnt := COUNT(NOFOLD(ds));

indexRecords := COUNT(files.manyIndex123);

expected := MAP(
    indexRecords <= 0x10000 => indexRecords,
    indexRecords <= 0x20000 => 0x10000,
    indexRecords <= 0x30000 => indexRecords - 0x10000,
    0x20000);

OUTPUT(cnt = expected);
