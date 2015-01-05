//class=memory
//class=quick
//class=create

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

LOADXML('<xml/>');

ds(unsigned i) := DATASET(config.simpleRecordCount DIV config.SplitWidth, format.createSimple(COUNTER+i), DISTRIBUTED);

dsAll := DATASET([], format.simpleRec)

#declare(i)
#set(I,0)
#loop
  & ds(%I%)
  #set(I,%I%+1)
  #if (%I%>=config.SplitWidth)
    #break
  #end
#end
;

cnt := COUNT(NOFOLD(dsAll));

OUTPUT(cnt = (config.simpleRecordCount DIV config.SplitWidth) * config.SplitWidth);
