//class=memory
//class=quick
//class=create

import $ as suite;
import suite.perform.config;
import suite.perform.files;

ds := files.generateSimple();

cnt := COUNT(NOFOLD(ds));

OUTPUT(cnt = config.simpleRecordCount);
