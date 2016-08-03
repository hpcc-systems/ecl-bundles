//class=disk
//class=quick
//class=diskread

//version checkCrc=true,hintHeapFlags=0x80,timeActivities=false
//version checkCrc=false,hintHeapFlags=0x80,timeActivities=false
//version checkCrc=true,hintHeapFlags=0x00,timeActivities=false
//version checkCrc=false,hintHeapFlags=0x00,timeActivities=false
//version checkCrc=true,hintHeapFlags=0x80,timeActivities=true
//version checkCrc=false,hintHeapFlags=0x80,timeActivities=true
//version checkCrc=true,hintHeapFlags=0x00,timeActivities=true
//version checkCrc=false,hintHeapFlags=0x00,timeActivities=true
#option ('optimizeLevel',3)

import ^ as root;
import $ as suite;
import suite.perform.config, suite.perform.files;

checkCrc := #IFDEFINED(root.checkCrc, false);
timeActivities := #IFDEFINED(root.timeActivities, false);

#option('crcReadEnabled', checkCrc);
#option('timeActivities', timeActivities);

ds := files.diskSimple(false);

OUTPUT(COUNT(NOFOLD(ds)) = config.simpleRecordCount);
