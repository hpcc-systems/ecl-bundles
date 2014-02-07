import perform.config, perform.format, perform.files;

ds := files.generateSimple();

t := TABLE(ds, { id3, cnt := COUNT(group) }, id3);

output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
