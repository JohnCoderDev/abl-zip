USING Classes.BitWriter.BitWriter.

CLASS Classes.Encoders.LZ77Encoder:
    DEFINE PUBLIC PROPERTY searchBufferSize AS INT64 GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY aheadBufferSize AS INT64 GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY alphabet AS LONGCHAR GET. PRIVATE SET.
    DEFINE PRIVATE PROPERTY writer AS BitWriter GET. SET.
    
    DEFINE PRIVATE TEMP-TABLE pointers
        FIELD sequence AS INT64
        FIELD offset AS INTEGER
        FIELD len AS INTEGER
        FIELD nextChar AS CHARACTER
        INDEX idxSequence AS UNIQUE PRIMARY
            sequence ASCENDING.
    
    CONSTRUCTOR LZ77Encoder():
        ASSIGN 
            searchBufferSize = EXP(2, 13)
            aheadBufferSize = EXP(2, 8)
            writer = NEW BitWriter().
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID encodeAlphabet(a AS LONGCHAR):
        clearEncoder().
        parseAlphabet(a).
        alphabetToPointers().
        pointersToWriter().
    END METHOD.
    
    METHOD PUBLIC VOID parseAlphabet(a AS LONGCHAR):
        ASSIGN alphabet = a.
    END METHOD.
    
    METHOD PUBLIC VOID alphabetToPointers():
        DEFINE VARIABLE cursorPosition AS INT64 INITIAL 1.
        DEFINE VARIABLE bestMatches AS INT64 EXTENT 2.
        DEFINE VARIABLE nextSequence AS INT64 INITIAL 1.
        DEFINE VARIABLE searchSubstringStart AS INT64.
        DEFINE VARIABLE searchSubstringLength AS INT64.
        DEFINE VARIABLE aheadSubstring AS CHARACTER.
        DEFINE VARIABLE searchSubstring AS CHARACTER.
        DEFINE VARIABLE nextCharPosition AS INT64.
              
        DO WHILE cursorPosition < LENGTH(alphabet):
            ASSIGN
                searchSubstringStart = MAXIMUM(1, cursorPosition - searchBufferSize)
                searchSubstringLength = MINIMUM(cursorPosition - 1, searchBufferSize)
                searchSubstring = SUBSTRING(alphabet, searchSubstringStart, searchSubstringLength)
                aheadSubstring = SUBSTRING(alphabet, cursorPosition, aheadBufferSize)
                bestMatches = findBestMatch(searchSubstring, aheadSubstring)
                nextCharPosition = cursorPosition + bestMatches[2]. 
                
            CREATE pointers.
            ASSIGN
                pointers.sequence = nextSequence
                pointers.offset = bestMatches[1]
                pointers.len = bestMatches[2]
                pointers.nextChar = 
                    IF nextCharPosition > LENGTH(alphabet)
                    THEN ''
                    ELSE SUBSTRING(alphabet, nextCharPosition, 1)
                cursorPosition = nextCharPosition + 1
                nextSequence = nextSequence + 1.
        END.
    END METHOD.
    
    METHOD PUBLIC VOID pointersToWriter():
        FOR EACH pointers:
            writer:addVariadicBytes(pointers.offset).
            writer:addVariadicBytes(pointers.len).
            writer:addByte(pointers.nextChar).
        END.
    END METHOD.
    
    METHOD PUBLIC MEMPTR writeInMemory():
        RETURN writer:writeInMemory().
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(filepath AS CHARACTER):
        writer:writeFile(filepath).
    END METHOD.
    
    // return [offset, length]
    METHOD PRIVATE INT64 EXTENT 2 findBestMatch(
        searchSubstring AS LONGCHAR,
        aheadSubstring AS LONGCHAR
    ):
        DEFINE VARIABLE windowString AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE res AS INT64 EXTENT 2 NO-UNDO INITIAL [0, 0].
        DEFINE VARIABLE currentOffset AS INT64 INITIAL 0 NO-UNDO.
        DEFINE VARIABLE currentLength AS INT64 INITIAL 0 NO-UNDO.
        DEFINE VARIABLE idx AS INT64 NO-UNDO.
        DEFINE VARIABLE idy AS INT64 NO-UNDO.
        
        ASSIGN windowString = searchSubstring + aheadSubstring.
        
        DO idx = 1 TO LENGTH(searchSubstring):
            ASSIGN
                currentOffset = LENGTH(searchSubstring) - idx + 1
                currentLength = 0
                idy = 1.
            DO WHILE (SUBSTRING(aheadSubstring, idy, 1) = SUBSTRING(windowString, idx, 1)):
                ASSIGN 
                    currentLength = currentLength + 1
                    idx = idx + 1
                    idy = idy + 1.
               IF idy > LENGTH(aheadSubstring) THEN LEAVE. 
            END.
            IF currentLength > res[2] THEN DO:
                ASSIGN
                    res[1] = currentOffset
                    res[2] = currentLength.
            END.
        END.
        
        RETURN res.
    END METHOD.
    
    METHOD PUBLIC VOID setsearchBufferSize(newSearchBufferSize AS INT64):
        IF newSearchBufferSize < 2 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the window size could not be lower than 2',
                -300
            ).
        END.
        ASSIGN searchBufferSize = newsearchBufferSize.
    END METHOD.
    
    METHOD PUBLIC VOID setAheadBufferSize(newBufferSize AS INT64):
        IF newBufferSize < 2 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the ahead buffer size could not be lower than 2',
                -301
            ).
        END.
        ASSIGN aheadBufferSize = newBufferSize.
    END METHOD.
    
    METHOD PUBLIC VOID clearEncoder():
        EMPTY TEMP-TABLE pointers.
        writer:clearWriter().
    END METHOD.
END CLASS.
