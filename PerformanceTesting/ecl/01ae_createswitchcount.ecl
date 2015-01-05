//class=memory
//class=parallel
//class=create

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;

LOADXML('<xml/>');

ds := files.generateSimple();

expectedNumber := config.simpleRecordCount DIV config.splitWidth;

#declare(i)
#set(I,0)
#loop
#uniquename(cnt)
%cnt% := COUNT(NOFOLD(ds((id1 % config.SplitWidth) = %I%)));
OUTPUT(%cnt% BETWEEN expectedNumber and expectedNumber + 1);
  #set(I,%I%+1)
  #if (%I%>=config.SplitWidth)
    #break
  #end
#end
