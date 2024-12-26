USING Classes.Encoders.HuffmanEncoder.
USING Classes.BaseConverter.Dec2Bin.
USING Classes.BitWriter.BitWriter.

CLASS Classes.Encoders.CanonicalHuffmanEncoder:
    DEFINE PRIVATE PROPERTY he AS HuffmanEncoder GET. SET.
    DEFINE PRIVATE PROPERTY converter AS Dec2Bin GET. SET.
    DEFINE PRIVATE PROPERTY writer AS BitWriter GET. SET.
    
    DEFINE PUBLIC PROPERTY currentPhrase AS LONGCHAR GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY translatedPhrase AS LONGCHAR GET. PRIVATE SET.
    
    DEFINE PRIVATE TEMP-TABLE encodedCanonicalAlphabet
        FIELD alphaChar AS CHARACTER
        FIELD ncBinRep AS CHARACTER
        FIELD ncLength AS INT64
        FIELD canonicalBinRep AS CHARACTER
        INDEX idxCanonical AS PRIMARY UNIQUE
            ncLength ASCENDING
            alphaChar ASCENDING.
    
    CONSTRUCTOR CanonicalHuffmanEncoder():
        ASSIGN 
            he = NEW HuffmanEncoder()
            converter = NEW Dec2Bin()
            writer = NEW BitWriter()
            converter:alwaysShiftPrefix = TRUE.
        clearEncoder().
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID encodeAlphabetFromPhrase(a AS LONGCHAR):
        clearEncoder().
        parsePhrase(a).
        encodeCurrentAlphabet().
        translatePhrase().
    END METHOD.
    
    METHOD PUBLIC VOID parsePhrase(a AS LONGCHAR):
        setCurrentPhrase(a).
        he:parsePhrase(a).
    END METHOD.
    
    METHOD PUBLIC VOID encodeCurrentAlphabet():
        he:encodeCurrentAlphabet().
        encodeCanonicalAlphabet().
    END METHOD.
    
    METHOD PUBLIC LONGCHAR translatePhrase():
        DEFINE VARIABLE idx AS INT64 NO-UNDO.
        DEFINE VARIABLE cidx AS CHARACTER NO-UNDO.
        
        ASSIGN translatedPhrase = "".
        
        DO idx = 1 TO LENGTH(currentPhrase):
            ASSIGN cidx = SUBSTRING(currentPhrase, idx, 1).
            FIND FIRST encodedCanonicalAlphabet
                WHERE encodedCanonicalAlphabet.alphaChar = cidx.
            ASSIGN translatedPhrase = translatedPhrase + encodedCanonicalAlphabet.canonicalBinRep.
        END.
        
        RETURN translatedPhrase.
    END METHOD.
    
    METHOD PUBLIC MEMPTR writeInMemory():
        writer:clearWriter().
        writer:parseBitString(translatedPhrase).
        RETURN writer:writeInMemory().
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(filepath AS CHARACTER):
        writeFile(filepath, FALSE).
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(
        filepath AS CHARACTER,
        shouldAppend AS LOGICAL
    ):
        writer:clearWriter().
        writer:parseBitString(translatedPhrase).
        writer:writeFile(filepath, shouldAppend).
    END METHOD.
        
    METHOD PUBLIC VOID encodeCanonicalAlphabet():
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE bTable AS HANDLE NO-UNDO.
        DEFINE VARIABLE n AS INT64 NO-UNDO INITIAL 0.
        DEFINE VARIABLE nBinRep AS CHARACTER NO-UNDO.
        
        ASSIGN bTable = he:getEncodedAlphabetTableBuffer().
        
        
        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(bTable).
        hQuery:QUERY-PREPARE('FOR EACH ' + bTable:NAME).
        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        
        DO WHILE NOT hQuery:QUERY-OFF-END:
            CREATE encodedCanonicalAlphabet.
            ASSIGN
                encodedCanonicalAlphabet.alphaChar = bTable:BUFFER-FIELD('alphaChar'):BUFFER-VALUE
                encodedCanonicalAlphabet.ncBinRep = bTable:BUFFER-FIELD('binRep'):BUFFER-VALUE
                encodedCanonicalAlphabet.ncLength = LENGTH(encodedCanonicalAlphabet.ncBinRep).
            hQuery:GET-NEXT().
        END.
        
        FOR EACH encodedCanonicalAlphabet:
            ASSIGN nBinRep = converter:convertNumber(STRING(n)).
            
            DO WHILE encodedCanonicalAlphabet.ncLength > LENGTH(nBinRep):
                ASSIGN
                    n = n * 2
                    nBinRep = converter:convertNumber(STRING(n)).
            END.
            
            ASSIGN 
                encodedCanonicalAlphabet.canonicalBinRep = nBinRep
                n = n + 1.
        END.
        
        hQuery:QUERY-CLOSE.
        DELETE OBJECT hQuery.
    END METHOD.
    
    METHOD PUBLIC VOID setCurrentPhrase(a AS LONGCHAR):
        ASSIGN currentPhrase = a.
    END METHOD.
    
    METHOD PUBLIC VOID addCharToAlphabet(a AS CHARACTER):
        he:addCharToAlphabet(a).
    END METHOD.
    
    METHOD PUBLIC VOID addCharToAlphabet(
        a AS CHARACTER,
        w AS INT64
    ):
        he:addCharToAlphabet(a, w).
    END.
    
    METHOD PUBLIC VOID addCharToEncodedAlphabet(
        a AS CHARACTER,
        binRep AS CHARACTER
    ):
        he:addCharToEncodedAlphabet(a, binRep).
    END METHOD.
    
    METHOD PUBLIC VOID showEncodedTable():
        FOR EACH encodedCanonicalAlphabet:
            DISPLAY
                encodedCanonicalAlphabet
                WITH SCROLLABLE.
        END.        
    END METHOD.
    
    METHOD PUBLIC VOID clearEncoder():
        EMPTY TEMP-TABLE encodedCanonicalAlphabet.
        he:clearEncoder().
        writer:clearWriter().
        ASSIGN 
            currentPhrase = ""
            translatedPhrase = "".
    END METHOD.
END CLASS.
