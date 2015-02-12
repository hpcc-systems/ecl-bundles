//class=memory
//class=parallel
//class=create

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

LOADXML('<xml/>');

#declare(i)
#set(I,1)
#loop
#uniquename(cnt)
%cnt% := COUNT(NOFOLD(files.generateSimpleScaled(%I%-1, config.SplitWidth)(id1 != %I%)));
OUTPUT(%cnt% = (config.simpleRecordCount DIV config.SplitWidth) - 1);
  #set(I,%I%+1)
  #if (%I%>config.SplitWidth)
    #break
  #end
#end
