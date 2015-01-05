//class=disk
//class=quick
//class=diskread

import $ as suite;
import suite.perform.config, suite.perform.files;

ds := files.csvSimple(false);

OUTPUT(COUNT(NOFOLD(ds)) = config.simpleRecordCount);
