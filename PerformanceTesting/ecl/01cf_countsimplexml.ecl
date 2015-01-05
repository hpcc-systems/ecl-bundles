//class=disk
//class=quick
//class=diskread

import $ as suite;
import suite.perform.config, suite.perform.files;

ds := files.xmlSimple(false);

OUTPUT(COUNT(NOFOLD(ds)) = config.simpleRecordCount);
