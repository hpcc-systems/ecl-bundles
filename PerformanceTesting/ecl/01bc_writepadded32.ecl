//class=disk
//class=diskwrite

import perform.config;
import perform.format;
import perform.files;

ds := DATASET(config.simpleRecordCount, format.createPadded(COUNTER), DISTRIBUTED);

OUTPUT(ds,,files.paddedName+'_uncompressed',overwrite);
