import perform.config, perform.format, perform.files;
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
