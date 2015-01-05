//class=memory
//class=parallel
//class=create

import $ as suite;
import suite.perform.create;

LOADXML('<xml/>');

dsAll := create.orderedAppend(32);

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV 32) * 32);
