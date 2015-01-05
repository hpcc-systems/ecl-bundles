//class=disk
//class=diskwrite
//class=setup

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := DATASET(config.simpleRecordCount, format.createSimple(COUNTER), DISTRIBUTED);

OUTPUT(ds,,files.simpleName+'_compressed',COMPRESSED, overwrite);
