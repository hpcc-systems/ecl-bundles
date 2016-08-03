//class=memory
//class=quick
//class=create

//version timeActivities=true
//version timeActivities=false

import ^ as root;
import $ as suite;
import suite.perform.config, suite.perform.files;

timeActivities := #IFDEFINED(root.timeActivities, true);

#option('timeActivities', timeActivities);

import $ as suite;
import suite.perform.config;
import suite.perform.files;

ds := files.generateSimple();

cnt := COUNT(NOFOLD(ds));

OUTPUT(cnt = config.simpleRecordCount);
