import perform.config, perform.format, perform.files;

ds := files.generateSimple();

t := DEDUP(ds, id3, HASH);

output(COUNT(NOFOLD(t)) = config.simpleRecordCount);
