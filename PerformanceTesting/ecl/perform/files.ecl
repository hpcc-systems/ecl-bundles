import perform.config, perform.format;

export files := MODULE
    export prefix := '~perform::' + __PLATFORM__ + '::';
    export simpleName := prefix + 'simple';
    export paddedName := prefix + 'padded';

    export generateN(unsigned delta = 0, unsigned num) := DATASET(num, format.createSimple(COUNTER + delta), DISTRIBUTED);

    export generateSimple(unsigned delta = 0) := DATASET(config.simpleRecordCount, format.createSimple(COUNTER + delta), DISTRIBUTED);

    export generateSimpleScaled(unsigned delta = 0, unsigned scale) := generateN(delta, config.simpleRecordCount DIV scale);

    export generatePadded() := DATASET(config.simpleRecordCount, format.createPadded(COUNTER), DISTRIBUTED);

    EXPORT suffix(boolean compressed) := IF(compressed, '_compressed', '_uncompressed');

    export diskSimple(boolean compressed) := DATASET(simpleName+suffix(compressed), format.simpleRec, FLAT);

    export csvSimple(boolean compressed) := DATASET(simpleName+suffix(compressed)+'_csv', format.simpleRec, CSV);

    export xmlSimple(boolean compressed) := DATASET(simpleName+suffix(compressed)+'_xml', format.simpleRec, XML('', NOROOT));

    export diskPadded(boolean compressed) := DATASET(paddedName+suffix(compressed), format.paddedRec, FLAT);

    export diskSplit(unsigned part) := DATASET(paddedName+suffix(false)+'_' + (string)part, format.simpleRec, FLAT);

END;
