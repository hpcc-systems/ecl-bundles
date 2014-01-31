import perform.config, perform.format, perform.files;

ds := files.generateSimple();

d := DISTRIBUTE(ds, id3);
t := TABLE(NOFOLD(d), { id3, cnt := COUNT(group) }, id3);
output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
