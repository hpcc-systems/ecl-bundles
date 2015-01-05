export create := MODULE
    export orderedAppend(splitWidth) := FUNCTIONMACRO
        //Relative imports in a function macro are not going to work very well.
        import perform.config, perform.format;
        LOCAL ds(unsigned i) := DATASET(config.simpleRecordCount DIV SplitWidth, format.createSimple(COUNTER+i), DISTRIBUTED);

        LOCAL dsAll := DATASET([], format.simpleRec)

        #declare(i)
        #set(I,0)
        #loop
          + ds(%I%)
          #set(I,%I%+1)
          #if (%I%>=SplitWidth)
            #break
          #end
        #end
        ;

        RETURN dsAll;
    ENDMACRO;
END;
