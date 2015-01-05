//class=disk
//class=diskwrite
//class=setup

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

ds := DATASET(config.simpleRecordCount, format.createPadded(COUNTER), DISTRIBUTED);

OUTPUT(ds,,files.paddedName+'_uncompressed',overwrite);
