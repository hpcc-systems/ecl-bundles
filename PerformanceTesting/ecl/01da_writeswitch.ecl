import perform.config, perform.format, perform.files;
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
