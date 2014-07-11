//class=memory
//class=parallel
//class=create

import perform.create;

LOADXML('<xml/>');

dsAll := create.orderedAppend(4);

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV 4) * 4);
