//class=memory
//class=stress
//class=sort

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

numRecords := config.simpleRecordCount * 16;
ds := files.generateN(0, numRecords);

sortedDs := sort(ds, id3);

output(COUNT(NOFOLD(sortedDs)) = numRecords);
