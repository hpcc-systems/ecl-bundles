//class=disk
//class=diskwrite
//class=setup

import perform.config;
import perform.format;
import perform.files;

ds := DATASET(config.simpleRecordCount, format.createPadded(COUNTER), DISTRIBUTED);

OUTPUT(ds,,files.paddedName+'_compressed',COMPRESSED, overwrite);
