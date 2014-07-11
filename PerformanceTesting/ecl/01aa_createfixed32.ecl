//class=memory
//class=quick
//class=create

import perform.config;
import perform.format;
import perform.files;

ds := files.generateSimple();

cnt := COUNT(NOFOLD(ds));

OUTPUT(cnt = config.simpleRecordCount);
