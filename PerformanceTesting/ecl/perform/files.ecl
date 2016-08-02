import $.config, $.format;

export files := MODULE
    export platform := __PLATFORM__;
    export prefix := '~perform::' + platform + '::';
    export thorprefix := '~perform::thorlcr::';
    export simpleName := prefix + 'simple';
    export paddedName := prefix + 'padded';
    export indexName := prefix + 'index';

    export generateN(unsigned delta = 0, unsigned num) := NOFOLD(DATASET(num, format.createSimple(COUNTER + delta), DISTRIBUTED));

    export generateSimple(unsigned delta = 0) := DATASET(config.simpleRecordCount, format.createSimple(COUNTER + delta), DISTRIBUTED,HINT(heapflags(config.heapFlags)));

    export generateSimpleScaled(unsigned delta = 0, unsigned scale) := generateN(delta, config.simpleRecordCount DIV scale);

    export generatePadded() := NOFOLD(DATASET(config.simpleRecordCount, format.createPadded(COUNTER), DISTRIBUTED));

    EXPORT suffix(boolean compressed) := IF(compressed, '_compressed', '_uncompressed');

    export diskSimple(boolean compressed) := DATASET(simpleName+suffix(compressed), format.simpleRec, FLAT, HINT(heapflags(config.heapFlags)));

    export csvSimple(boolean compressed) := DATASET(simpleName+suffix(compressed)+'_csv', format.simpleRec, CSV);

    export xmlSimple(boolean compressed) := DATASET(simpleName+suffix(compressed)+'_xml', format.simpleRec, XML('', NOROOT));

    export diskPadded(boolean compressed) := DATASET(paddedName+suffix(compressed), format.paddedRec, FLAT);

    export diskSplit(unsigned part) := DATASET(paddedName+suffix(false)+'_' + (string)part, format.simpleRec, FLAT);

    export manyIndex123 := INDEX({ 
        unsigned1 id1a;
        unsigned1 id1b;
        unsigned1 id1c;
        unsigned1 id1d;
        unsigned1 id1e;
        unsigned1 id1f;
        unsigned1 id1g;
        unsigned1 id1h;
        unsigned8 id2, unsigned8 id3 }, { unsigned8 id4 }, thorprefix + 'index_id1xid2id3id4');
    
    export manyIndex321 := INDEX({ 
        unsigned1 id3a;
        unsigned1 id3b;
        unsigned1 id3c;
        unsigned1 id3d;
        unsigned1 id3e;
        unsigned1 id3f;
        unsigned1 id3g;
        unsigned1 id3h;
        unsigned8 id2, unsigned8 id1 }, { unsigned8 id4 }, thorprefix + 'index_id3xid2id1id4');
    
    export singleIndex := INDEX({ 
        unsigned1 id1a;
        unsigned1 id1b;
        unsigned1 id1c;
        unsigned1 id1d;
        unsigned1 id1e;
        unsigned1 id1f;
        unsigned1 id1g;
        unsigned1 id1h;
        unsigned8 id2, unsigned8 id3 }, { unsigned8 id4 }, thorprefix + 'index_id1xid2id3id4_1');
END;
