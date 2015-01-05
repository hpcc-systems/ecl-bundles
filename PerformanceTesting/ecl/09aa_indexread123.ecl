//class=index
//class=indexread

import $ as suite;
import suite.perform.config;
import suite.perform.format;
import suite.perform.files;
import suite.perform.util;


ds := files.manyIndex123(
            id1a = 0 AND 
            id1b = 0 AND 
            id1c = 0 AND 
            id1d = 0 AND 
            id1e = 0 AND 
            id1f IN [1,3]);
             
cnt := COUNT(NOFOLD(ds));

OUTPUT(cnt = 256 * 256 * 2);
