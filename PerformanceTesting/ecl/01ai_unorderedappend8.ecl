//class=memory
//class=parallel
//class=create

import $ as suite;
import suite.perform.create;

LOADXML('<xml/>');

dsAll := create.orderedAppend(8);

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV 8) * 8);
