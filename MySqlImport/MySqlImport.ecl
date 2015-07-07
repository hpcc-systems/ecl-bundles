IMPORT MySql,Std;

EXPORT MySqlImport := MODULE, FORWARD

    /***************************************************************************
     * To use this bundle, execute the bundle, specificing the database, user
     * and password on the command line:
     *
     * ecl run MySqlImport.ecl -xdatabase=mydb -xuser=ghalliday -xpassword=password
     *
     * The bundle outputs a single string as a result which contains a module
     * that can be used to access all the tables in the MySql database
     *
     **************************************************************************/

    EXPORT Bundle := MODULE(Std.BundleBase)
        EXPORT Name := 'MySqlImport';
        EXPORT Description := 'Create record and dataset definitions from MySQL tables';
        EXPORT Authors := ['Gavin Halliday'];
        EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
        EXPORT Copyright := 'Copyright (C) 2015 HPCC Systems';
        EXPORT DependsOn := [];
        EXPORT Version := '1.0.0';
    END;

    EXPORT fullModuleText(string database, string user, string password) := FUNCTION

        columnRecord := RECORD
            string name;
            string kind;
            DATA fullkind;
            unsigned maxlen;
        END;

        tableRecord := RECORD
            string table_name;
            string comment;
        END;

        dataset(tableRecord) myTables(string schema) := EMBED(mySql : database(database),user(user),password(password))
            SELECT table_name, table_comment FROM information_schema.tables WHERE table_type='BASE TABLE' AND table_schema=?;
        ENDEMBED;

        dataset(columnRecord) getColumns(string table) := EMBED(mySql : database(database),user(user),password(password))
            SELECT column_name, data_type,column_type,character_maximum_length FROM information_schema.columns WHERE table_name=?;
        ENDEMBED;

        fullRecord := RECORD(tableRecord)
            DATASET(columnRecord) columns;
        END;

        fullRecord addColumns(tableRecord l) := TRANSFORM
            SELF.columns := getColumns(l.table_name);
            SELF := l;
        END;

        p := PROJECT(myTables(database), addColumns(LEFT));

        textRecord := { string text; };

        getEnumType(columnRecord col) := FUNCTION
            RETURN (STRING) col.fullkind;
        END;

        getDecimalType(columnRecord col) := FUNCTION
            fullKind := (string)col.fullKind;
            openBra := Std.Str.Find(fullKind, '(');
            comma := Std.Str.Find(fullKind, ',');
            closeBra := Std.Str.Find(fullKind, ')');
            //Code generator really should support decimal(n,x) as a syntax
            RETURN 'DECIMAL' + fullKind[openBra+1..comma-1]+'_' + fullKind[comma+1..closebra-1];
        END;

        eclType(columnRecord col) := DEFINE FUNCTION
            isUnsigned := Std.Str.Find((string)col.fullkind,'unsigned') != 0;
            RETURN CASE(col.kind,
                    'tinyint'=>      IF(isUnsigned,'UNSIGNED1','INTEGER1'),
                    'smallint'=>     IF(isUnsigned,'UNSIGNED2','INTEGER2'),
                    'mediumint'=>    IF(isUnsigned,'UNSIGNED3','INTEGER3'),
                    'int'=>          IF(isUnsigned,'UNSIGNED4','INTEGER4'),
                    'bigint'=>       IF(isUnsigned,'UNSIGNED','INTEGER'),
                    'float'=>'REAL4',
                    'double'=>'REAL8',
                    'datetime'=>'DATETIME_T',
                    'timestamp'=>'TIMESTAMP_T',
                    'time'=>'TIME_T',
                    'date'=>'DATE_T',
                    'blob'=>'DATA',
                    'longblob'=>'DATA',
                    'char'=>'STRING'+col.maxlen,
                    'varchar'=>'STRING',
                    'longtext'=>'DATA', // Should really be allowed to be a string
                    'decimal'=>getDecimalType(col),
                    'enum'=>getEnumType(col),
                    col.kind);
        END;

        reservedKeywords := ['end','record'];

        //Ensure the output doesn't contain field names which are reserved words.
        string mapFieldName(string name) := DEFINE
            IF (name IN reservedKeywords, '_'+name, name);

        textRecord makeEcl(columnRecord l) := TRANSFORM
            SELF.text := '        ' + eclType(l) + ' ' + mapFieldName(l.name) + ';';
        END;

        nestedTextRec:= RECORD
            string recordText;
            string datasetText;
        END;

        nestedTextRec convertColumns(fullRecord l) := TRANSFORM
            mapped := PROJECT(l.columns, makeECL(LEFT));
            combined := AGGREGATE(mapped, textRecord, TRANSFORM(textRecord, SELF.text := RIGHT.text + LEFT.text + '\n'));
            recordName := l.table_name + 'Record';
            beginRecord := recordName + ' := RECORD\n';
            endRecord := '    END;\n';
            SELF.recordText := beginRecord + combined[1].text + endRecord;
            SELF.datasetText := 'DATASET(' + recordName + ') ' + l.table_name + 'Dataset() := EMBED(mySql : database(\'' + database + '\'), user(user), password(password))\n' + '        SELECT * FROM ' + l.table_name + ';\n    ENDEMBED;\n';
        END;

        p2 := PROJECT(p, convertColumns(LEFT));

        nestedTextRec createModule(nestedTextRec l, nestedTextRec r) := TRANSFORM
            SELF.recordText := r.recordText + '    EXPORT ' + l.recordText + '\n';
            SELF.datasetText := r.datasetText + '    EXPORT ' + l.datasetText + '\n';
        END;

        p3 := AGGREGATE(p2, nestedTextRec, createModule(LEFT, RIGHT));

        RETURN
            'IMPORT MySql;\n\n' +
            'EXPORT ' + database + 'Database(string user, string password) := MODULE\n' +
            '    EXPORT TIME_T := STRING8;       // HH:MM:SS\n\n' +
            '    EXPORT DATE_T := STRING10;      // YYYY-MM-DD\n\n' +
            '    EXPORT TIMESTAMP_T := STRING19; // YYYY-MM-DD HH:MM:SS\n\n' +
            '    EXPORT DATETIME_T := STRING19;  // YYYY-MM-DD HH:MM:SS\n\n' +
            p3[1].recordText +
            p3[1].datasetText +
            'END;\n';
    END;

    string database := '' : stored('database');
    string user := '' : stored('user');
    string password := '' : stored('password');

    EXPORT Main() := PARALLEL(OUTPUT(user), OUTPUT(fullModuleText(database, user, password)));
END;
