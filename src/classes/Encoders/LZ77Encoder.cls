CLASS Classes.Encoders.LZ77Encoder:
    DEFINE PUBLIC PROPERTY windowSize AS INT64 GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY aheadBufferSize AS INT64 GET. PRIVATE SET.
    DEFINE PRIVATE PROPERTY alphabet AS LONGCHAR GET. SET.
    
    DEFINE PRIVATE TEMP-TABLE pointers
        FIELD sequence AS INT64
        FIELD offset AS INT64
        FIELD len AS INT64
        FIELD nextChar AS CHARACTER
        INDEX idxSequence AS UNIQUE PRIMARY
            sequence ASCENDING.
    
    CONSTRUCTOR LZ77Encoder():
        ASSIGN 
            windowSize = EXP(2, 9)
            aheadBufferSize = EXP(2, 5).
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID parseAlphabet(a AS LONGCHAR):
        ASSIGN alphabet = a.
    END METHOD.
    
    METHOD PUBLIC VOID alphabetToPointers():
        DEFINE VARIABLE cursorPosition AS INT64 INITIAL 2.
        DEFINE VARIABLE bestMatches AS INT64 EXTENT 2.
        DEFINE VARIABLE aheadSubstring AS CHARACTER.
        DEFINE VARIABLE windowSubstring AS CHARACTER.
        DEFINE VARIABLE nextSequence AS INT64 INITIAL 2.
        DEFINE VARIABLE nextCharPosition AS INT64.
        
        CREATE pointers.
        ASSIGN
            pointers.sequence = 1
            pointers.offset = 0
            pointers.len = 0
            pointers.nextChar = SUBSTRING(alphabet, 2, 1).
        
        DO WHILE (
            cursorPosition 
            + windowSize 
            + aheadBufferSize
        ) < LENGTH(alphabet):
            ASSIGN
                windowSubstring = SUBSTRING(alphabet, cursorPosition, windowSize)
                aheadSubstring = SUBSTRING(alphabet, cursorPosition + windowSize, aheadBufferSize)
                bestMatches = findBestMatch(windowSubstring, aheadSubstring).
            
            CREATE pointers.
            ASSIGN
                pointers.sequence = nextSequence
                pointers.offset = bestMatches[1]
                pointers.len = bestMatches[2]
                
                nextCharPosition = cursorPosition + windowSize + pointers.len
                nextCharPosition = MINIMUM(nextCharPosition, LENGTH(alphabet))
                
                pointers.nextChar = SUBSTRING(alphabet, nextCharPosition, 1)
                cursorPosition = nextCharPosition + 1
                nextSequence = nextSequence + 1.
        END.
    END METHOD.
    
    METHOD PRIVATE INT64 EXTENT 2 findBestMatch(
        windowSubstring AS CHARACTER,
        aheadSubstring AS CHARACTER
    ):
        DEFINE VARIABLE res AS INT64 EXTENT 2.
        // todo: implement the logic to find the best matches
        
        RETURN res.
    END METHOD.
    
    METHOD PUBLIC VOID setWindowSize(newWindowSize AS INT64):
        IF newWindowSize < 2 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the window size could not be lower than 2',
                -300
            ).
        END.
        ASSIGN windowSize = newWindowSize.
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
    END METHOD.
END CLASS.
