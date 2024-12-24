CLASS Classes.BaseConverter.BaseConverter:
    DEFINE PUBLIC PROPERTY baseTarget AS INTEGER GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY baseSource AS INTEGER GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY targetSymbols AS CHARACTER GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY sourceSymbols AS CHARACTER GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY targetPrefix AS CHARACTER GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY sourcePrefix AS CHARACTER GET. PRIVATE SET.
    
    METHOD PUBLIC VOID setBaseTarget(
        base AS INTEGER,
        symbols AS CHARACTER,
        prefix AS CHARACTER
    ):
        validateBaseArguments(base, symbols, prefix).
        IF NOT prefix MATCHES "*x" THEN DO:
            ASSIGN prefix = prefix + "x".        
        END.
        ASSIGN
            baseTarget = base
            targetSymbols = symbols
            targetPrefix = prefix.
    END METHOD.
    
    METHOD PUBLIC VOID setBaseSource(
        base AS INTEGER,
        symbols AS CHARACTER,
        prefix AS CHARACTER
    ):
        
        validateBaseArguments(base, symbols, prefix).
        IF NOT prefix MATCHES "*x" THEN DO:
            ASSIGN prefix = prefix + "x".        
        END.
        ASSIGN
            baseSource = base
            sourceSymbols = symbols
            sourcePrefix = prefix.
    END METHOD.
    
    METHOD PUBLIC CHARACTER convertNumber(n AS CHARACTER):
        DEFINE VARIABLE sourceNumber AS CHARACTER.
        DEFINE VARIABLE targetNumber AS CHARACTER.
        DEFINE VARIABLE remainder AS INT64.
        DEFINE VARIABLE symbol AS CHARACTER.
        DEFINE VARIABLE nb10 AS INT64.
        
        IF n MATCHES sourcePrefix + "*" THEN DO:
            sourceNumber = SUBSTRING(n, LENGTH(sourcePrefix) + 1).
        END.
        ELSE DO:
            sourceNumber = n.
        END.
        
        validateSymbols(sourceNumber, sourceSymbols).
        ASSIGN nb10 = convertInBase10Number(
            sourceNumber, 
            sourceSymbols
        ).
        
        IF baseTarget = 10 THEN DO:
            RETURN targetPrefix + STRING(nb10).
        END.
        
        IF nb10 = 0 THEN DO:
            ASSIGN targetNumber = SUBSTRING(targetSymbols, 1, 1).
        END.
        DO WHILE nb10 > 0:
            ASSIGN
                remainder = nb10 MOD baseTarget
                nb10 = TRUNCATE(nb10 / baseTarget, 0)
                symbol = SUBSTRING(targetSymbols, remainder + 1, 1) 
                targetNumber = symbol + targetNumber.
        END.
        
        RETURN targetPrefix + targetNumber.
    END METHOD.
    
    METHOD PUBLIC CHARACTER convertNumber(
        n AS CHARACTER,
        shiftPrefix AS LOGICAL
    ):
        DEFINE VARIABLE res AS CHARACTER.
        ASSIGN res = convertNumber(n).
        IF shiftPrefix THEN DO:
            res = shiftTargetNumberPrefix(res).
        END.
        RETURN res.
    END METHOD.
    
    METHOD PUBLIC CHARACTER shiftTargetNumberPrefix(n AS CHARACTER):
        RETURN shiftNumberPrefix(n, targetPrefix).
    END METHOD.
    
    METHOD PUBLIC CHARACTER shiftSourceNumberPrefix(n AS CHARACTER):
        RETURN shiftNumberPrefix(n, sourcePrefix).
    END METHOD.
    
    METHOD PRIVATE CHARACTER shiftNumberPrefix(
        n AS CHARACTER,
        prefix AS CHARACTER
    ):
        DEFINE VARIABLE res AS CHARACTER.
        IF n BEGINS prefix THEN DO:
            ASSIGN res = SUBSTRING(n, LENGTH(prefix) + 1).
        END.
        ELSE DO:
            res = n.
        END.
        RETURN res.
    END METHOD.
    
    METHOD PRIVATE INT64 convertInBase10Number(
        n AS CHARACTER,
        symbols AS CHARACTER
    ):
        DEFINE VARIABLE idx AS INTEGER.
        DEFINE VARIABLE res AS INT64 INITIAL 0.
        DEFINE VARIABLE cidx AS CHARACTER.
        
        DO idx = 1 TO LENGTH(n):
            ASSIGN
                cidx = SUBSTRING(n, idx, 1)
                res = res + (INDEX(symbols, cidx) - 1) * EXP(baseSource, LENGTH(n) - idx).
        END.
        RETURN res.
    END METHOD.
    
    METHOD PRIVATE VOID validateSymbols(
        n AS CHARACTER,
        symbols AS CHARACTER
    ):
        DEFINE VARIABLE idx AS INTEGER.
        DEFINE VARIABLE cidx AS CHARACTER.
        DO idx = 1 TO LENGTH(n):
            ASSIGN cidx = SUBSTRING(n, idx, 1). 
            IF NOT symbols MATCHES "*" + cidx + "*" THEN DO:
                UNDO, THROW NEW PROGRESS.Lang.AppError(
                    'unknown symbol `' + cidx + '`',
                    -104
                ).
            END.    
        END.
    END METHOD.
    
    METHOD PRIVATE VOID validateBaseArguments(
        base AS INTEGER,
        symbols AS CHARACTER,
        prefix AS CHARACTER
    ):
       IF base < 2 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the base number must be at least 2',
                -100
            ).
        END.
        IF LENGTH(symbols) <> base THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the number of symbols does not match the base',
                -101
            ).
        END.
        IF symbols MATCHES "*x*" THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the symbols must not contain "x" because its reserved',
                -102
            ).
        END.
        IF INDEX(symbols, "*") > 0 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'the symbols must not contain "*" because its reserved',
                -103
            ).
        END.
    END METHOD.
END CLASS.
