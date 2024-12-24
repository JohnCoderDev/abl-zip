USING Classes.BaseConverter.*.

CLASS Classes.BitWriter.BitWriter:
    DEFINE TEMP-TABLE bytesTable
        FIELD byteSequence AS INT64
        FIELD byteCode AS INTEGER
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
        OUTPUT TO VALUE(filepath) BINARY.
            FOR EACH bytesTable:
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
        DEFINE VARIABLE byteValue AS INTEGER.
        
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
        DEFINE VARIABLE hexByteValue AS INTEGER.
        ASSIGN hexString = REPLACE(hexString, ' ', '').
        
        DO idx = 1 TO LENGTH(hexString) BY 2:
            ASSIGN
                hexByteString = SUBSTRING(hexString, idx, 2)
                hexByteValue = INT(hexConverter:convertNumber(hexByteString)).
            addByte(hexByteValue).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID addByte(b AS INTEGER):
        IF b > 255 OR b < 0 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'trying to add byte out of range',
                -1
            ).
        END.
        CREATE bytesTable.
        ASSIGN
            bytesTable.byteCode = b
            bytesTable.byteSequence = nextSequence
            nextSequence = nextSequence + 1.
    END METHOD.
    
    METHOD PUBLIC VOID addByte(b AS CHARACTER):
        IF LENGTH(b) <> 1 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'a byte parsed as char must have length exactly equals to 1',
                -2
            ).
        END.
        DEFINE VARIABLE byteChar AS INTEGER.
        ASSIGN byteChar = ASC(b).
        CREATE bytesTable.
        ASSIGN
            bytesTable.byteCode = byteChar
            bytesTable.byteSequence = nextSequence
            nextSequence = nextSequence + 1.
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
        n AS INTEGER
    ):
        IF n > 8 OR n < 1 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the number of bytes must be in range 1 and 8',
                -4
            ).
        END.
        
        DEFINE VARIABLE bytes AS INTEGER EXTENT 8.
        DEFINE VARIABLE idx AS INTEGER.
        
        DO idx = n TO 1 BY -1:
            ASSIGN 
                bytes[idx] = b MOD 256
                b = TRUNCATE(b / 256, 0).
        END.
        
        DO idx = 1 TO n:
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
