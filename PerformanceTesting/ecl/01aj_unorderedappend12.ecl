//class=memory
//class=parallel
//class=create

import perform.create;

LOADXML('<xml/>');

dsAll := create.orderedAppend(12);

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV 12) * 12);
