//class=memory
//class=parallel
//class=create

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

LOADXML('<xml/>');

ds := files.generateSimple();

#declare(i)
#set(I,1)
#loop
#uniquename(cnt)
%cnt% := COUNT(NOFOLD(ds(id1 != %I%)));
OUTPUT(%cnt% = config.simpleRecordCount - 1);
  #set(I,%I%+1)
  #if (%I%>config.SplitWidth)
    #break
  #end
#end
