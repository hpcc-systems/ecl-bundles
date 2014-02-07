export util := MODULE
    export unsigned1 byte(unsigned8 value, unsigned pos) := (unsigned1)(value >> (8 * (7-pos)));
END;
