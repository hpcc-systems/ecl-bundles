import perform.create;

LOADXML('<xml/>');

dsAll := create.orderedAppend(16);

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV 16) * 16);
