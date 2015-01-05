//class=disk
//class=parallel
//class=diskread

import $ as suite;
import suite.perform.config, suite.perform.format, suite.perform.files;
LOADXML('<xml/>');

ds := files.diskSimple(false);

#declare(i)
#set(I,0)
#loop
#uniquename(stream)
%stream% := NOFOLD(ds((id1 % config.SplitWidth) = %I%));
OUTPUT(%stream%,,files.simpleName+'_uncompressed_' + %'I'%,OVERWRITE);
  #set(I,%I%+1)
  #if (%I%>=config.SplitWidth)
    #break
  #end
#end
