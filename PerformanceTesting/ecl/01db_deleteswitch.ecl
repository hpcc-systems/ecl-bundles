//class=disk
//class=parallel
//class=diskread

//NOTE: class matches test 01da so the files get cleaned up

import $ as suite;
import suite.perform.config, suite.perform.format, suite.perform.files;
import Std.File;
#option ('pickBestEngine', false);

LOADXML('<xml/>');

#declare(i)
#set(I,0)
#loop
#uniquename(stream)
File.DeleteLogicalFile(files.simpleName+'_uncompressed_' + %'I'%, FALSE);
  #set(I,%I%+1)
  #if (%I%>=config.SplitWidth)
    #break
  #end
#end
