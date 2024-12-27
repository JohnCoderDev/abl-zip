CLASS Classes.BitWriter.BitShifter:
    METHOD PUBLIC STATIC INT64 shiftLeftBytes(n AS INT64, cb AS INT64):
        IF cb <= 0 THEN RETURN n.
        validateBytesNotOutOfRange(cb).
        RETURN shiftLeft(n, cb * 8).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 shiftLeft(n AS INT64, c AS INT64):
        IF c <= 0 THEN RETURN n.
        validateBitsNotOutOfRange(c).
        IF n = 0 THEN n = 1.
        RETURN INT64(n * EXP(2, c)).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 shiftRightBytes(n AS INT64, cb AS INT64):
        IF cb <= 0 OR n = 0 THEN RETURN n.
        RETURN shiftRight(n, cb * 8).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 shiftRight(n AS INT64, c AS INT64):
        IF c <= 0 OR n = 0 THEN RETURN n.
        RETURN INT64(TRUNCATE(n / EXP(2, c), 0)).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 getBytesFromLeft(n AS INT64, lb AS INT64):
        RETURN getBitsFromLeft(n, lb * 8).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 getBitsFromLeft(n AS INT64, l AS INT64):
        IF n < 0 OR l < 0 THEN RETURN 0.
        
        DEFINE VARIABLE bc AS INT64 NO-UNDO INITIAL 0.
        ASSIGN bc = countBytes(n) * 8.
        
        IF bc < l THEN RETURN n.
        RETURN shiftRight(n, bc - l).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 getBytesFromRight(n AS INT64, lb AS INT64):
        RETURN getBitsFromRight(n, lb * 8).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 getBitsFromRight(n AS INT64, l AS INT64):
        IF n = 0 OR l <= 0 THEN RETURN 0.
        RETURN INT64(n MOD EXP(2, l)).
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 countBytes(n AS INT64):
        DEFINE VARIABLE c AS INT64 INITIAL 0 NO-UNDO.
        IF n = 0 THEN RETURN 1.
        DO WHILE n > 0:
            ASSIGN
                n = shiftRightBytes(n, 1)
                c = c + 1.
        END.
        RETURN c.
    END METHOD.
    
    METHOD PUBLIC STATIC INT64 countBits(n AS INT64):
        DEFINE VARIABLE c AS INT64 INITIAL 0 NO-UNDO.
        IF n = 0 THEN RETURN 1.
        DO WHILE n > 0:
            ASSIGN
                n = shiftRight(n, 1)
                c = c + 1.
        END.
        RETURN c.
    END METHOD.
    
    METHOD PUBLIC STATIC LOGICAL fitsKBits(n AS INT64, k AS INT64):
        RETURN countBits(n) <= k.
    END METHOD.
    
    METHOD PUBLIC STATIC LOGICAL fitsKBytes(n AS INT64, k AS INT64):
        RETURN countBytes(n) <= k. 
    END METHOD.
    
    METHOD PRIVATE STATIC VOID validateBytesNotOutOfRange(b AS INT64):
        IF b > 8 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the limit is up to 8 bytes, no more than that',
                -500
            ).
        END.
    END METHOD.
    
    METHOD PRIVATE STATIC VOID validateBitsNotOutOfRange(b AS INT64):
         IF b > 64 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the limit is up to 64 bits, no more than that',
                -501
            ).
        END.
    END METHOD.
END CLASS.
