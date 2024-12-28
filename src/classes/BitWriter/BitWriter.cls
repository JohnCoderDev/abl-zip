USING Classes.BaseConverter.*.
USING Classes.BitWriter.BitShifter.

CLASS Classes.BitWriter.BitWriter:
    DEFINE TEMP-TABLE bytesTable
        FIELD byteSequence AS INT64
        FIELD byteCode AS INT64
        INDEX idxSequence AS PRIMARY UNIQUE byteSequence ASCENDING.
    
    DEFINE PRIVATE PROPERTY nextSequence AS INT64 INITIAL 1 GET. SET.
    DEFINE PRIVATE PROPERTY binConverter AS Bin2Dec GET. SET.
    DEFINE PRIVATE PROPERTY hexConverter AS Hex2Dec GET. SET.
    
    CONSTRUCTOR BitWriter():
        clearWriter().
        ASSIGN
            binConverter = NEW Bin2Dec()
            hexConverter = NEW Hex2Dec()
                        
            binConverter:alwaysShiftPrefix = TRUE
            hexConverter:alwaysShiftPrefix = TRUE.
    END CONSTRUCTOR.
    
    METHOD PUBLIC MEMPTR writeInMemory():
        DEFINE VARIABLE res AS MEMPTR.
        
        ASSIGN SET-SIZE(res) = nextSequence - 1.
        FOR EACH bytesTable:
            ASSIGN 
                PUT-BYTE(res, bytesTable.byteSequence) = bytesTable.byteCode.
        END.
        RETURN res.
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(filepath AS CHARACTER):
        writeFile(filepath, FALSE).
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(
        filepath AS CHARACTER,
        shouldAppend AS LOGICAL
    ):
        IF shouldAppend THEN
            OUTPUT TO VALUE(filepath) BINARY APPEND.
        ELSE 
            OUTPUT TO VALUE(filepath) BINARY.
        
        FOR EACH bytesTable:
            IF bytesTable.byteCode = 0 THEN
                PUT CONTROL NULL.
            ELSE 
                PUT UNFORMATTED CHR(bytesTable.byteCode).
        END.
        
        OUTPUT CLOSE.
    END METHOD.
    
    METHOD PUBLIC VOID parseASCII(asciiText AS LONGCHAR):
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE cidx AS CHARACTER.
        DO idx = 1 TO LENGTH(asciiText):
            ASSIGN cidx = SUBSTRING(asciiText, idx, 1).
            addByte(cidx).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID parseBitString(bitString AS LONGCHAR):
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE byteString AS CHARACTER.
        DEFINE VARIABLE byteValue AS INT64.
        
        ASSIGN bitString = REPLACE(bitString, ' ', '').
        
        DO idx = 1 TO LENGTH(bitString) BY 8:
            ASSIGN
                byteString = SUBSTRING(bitString, idx, 8)
                byteValue = INT(binConverter:convertNumber(byteString)).
            addByte(byteValue).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID parseHexString(hexString AS LONGCHAR):
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE hexByteString AS CHARACTER.
        DEFINE VARIABLE hexByteValue AS INT64.
        ASSIGN hexString = REPLACE(hexString, ' ', '').
        
        DO idx = 1 TO LENGTH(hexString) BY 2:
            ASSIGN
                hexByteString = SUBSTRING(hexString, idx, 2)
                hexByteValue = INT(hexConverter:convertNumber(hexByteString)).
            addByte(hexByteValue).
        END.
    END METHOD.

    METHOD PUBLIC VOID addByte(b AS CHARACTER):
        IF LENGTH(b) > 1 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'a byte parsed as char must not have length greater than 1',
                -2
            ).
        END.
        DEFINE VARIABLE byteCode AS INT64. 
        ASSIGN byteCode = IF LENGTH(b) = 0 THEN 0 ELSE ASC(b).
        addNBytes(byteCode, 1).
    END METHOD.
    
    METHOD PUBLIC VOID addByte(b AS INT64):
        addNBytes(b, 1).
    END METHOD.
    
    METHOD PUBLIC VOID add2Bytes(b AS INT64):
        addNBytes(b, 2).   
    END METHOD.
    
    METHOD PUBLIC VOID add4Bytes(b AS INT64):
        addNBytes(b, 4).
    END METHOD.
                                                                                         
    METHOD PUBLIC VOID add8Bytes(b AS INT64):
        addNBytes(b, 8).
    END METHOD.
    
    METHOD PUBLIC VOID addNBytes(
        b AS INT64,
        n AS INT64
    ):
        IF n > 8 OR n < 1 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the number of bytes must be in range 1 and 8',
                -4
            ).
        END.
        
        DEFINE VARIABLE idx AS INT64.
        DO idx = 1 TO n:
            CREATE bytesTable.
            ASSIGN 
                bytesTable.byteSequence = nextSequence
                bytesTable.byteCode = BitShifter:getBytesFromRight(b, 1)
                b = BitShifter:shiftRightBytes(b, 1)
                nextSequence = nextSequence + 1.
        END.
    END METHOD.
    
    METHOD PUBLIC VOID insertByte(
        b AS INT64,
        p AS INT64
    ):
        insertNBytes(b, 1, p).
    END METHOD.
    
    METHOD PUBLIC VOID insert2Bytes(
        b AS INT64,
        p AS INT64
    ):
        insertNBytes(b, 2, p).
    END.
    
    METHOD PUBLIC VOID insert4Bytes(
        b AS INT64,
        p AS INT64
    ):
        insertNBytes(b, 4, p).
    END METHOD.
    
    METHOD PUBLIC VOID insert8Bytes(
        b AS INT64,
        p AS INT64
    ):
        insertNBytes(b, 8, p).
    END METHOD.    
    
    METHOD PUBLIC VOID insertNBytes(
        b AS INT64,
        c AS INT64,
        p AS INT64
    ):
        IF c > 8 OR c < 1 THEN
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'count of bytes must be in range 1 up to 8',
                -6
            ).
        
        FOR EACH bytesTable 
        WHERE bytesTable.byteSequence >= p
        BY bytesTable.byteSequence DESCENDING:
            ASSIGN 
                bytesTable.byteSequence = bytesTable.byteSequence + c.
        END.
        
        ASSIGN nextSequence = nextSequence + c.
        
        DEFINE VARIABLE idx AS INT64.
        DO idx = p TO p + c:
            CREATE bytesTable.
            ASSIGN
                bytesTable.byteSequence = idx
                bytesTable.byteCode = BitShifter:getBytesFromRight(b, 1)
                b = BitShifter:shiftRightBytes(b, 1).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID addVariadicBytes(b AS INT64):
        addNBytes(b, INT(BitShifter:countBytes(b))).
    END METHOD.
    
    METHOD PUBLIC VOID addArrayOfBytes(bytes AS INT64 EXTENT):
        DEFINE VARIABLE idx AS INT64.
        DO idx = 1 TO EXTENT(bytes):
            addByte(bytes[idx]).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID removeByte(sequence AS INT64):
        FIND FIRST bytesTable
            WHERE bytesTable.byteSequence = sequence
            NO-ERROR.
        
        IF AVAILABLE bytesTable THEN DO:
            DELETE bytesTable.
            FOR EACH bytesTable
                WHERE bytesTable.byteSequence > sequence:
                ASSIGN
                    bytesTable.byteSequence = bytesTable.byteSequence - 1.
            END.
            ASSIGN nextSequence = nextSequence - 1.
        END.
    END METHOD.
    
    METHOD PUBLIC VOID clearWriter():
        EMPTY TEMP-TABLE bytesTable.
        ASSIGN nextSequence = 1.
    END METHOD.
END CLASS.
