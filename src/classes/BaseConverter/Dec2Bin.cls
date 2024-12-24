USING Classes.BaseConverter.BaseConverter.

CLASS Classes.BaseConverter.Dec2Bin:
    DEFINE PRIVATE PROPERTY converter AS BaseConverter GET. SET.
    DEFINE PRIVATE PROPERTY baseTargetSymbols AS CHARACTER GET. SET.
    DEFINE PRIVATE PROPERTY baseSourceSymbols AS CHARACTER GET. SET.
    DEFINE PUBLIC PROPERTY alwaysShiftPrefix AS LOGICAL GET. SET.
    
    CONSTRUCTOR Dec2Bin():
        ASSIGN
            converter = NEW BaseConverter()
            alwaysShiftPrefix = FALSE
            baseSourceSymbols = '0123456789'
            baseTargetSymbols = '01'.
        
        converter:setBaseSource(
            LENGTH(baseSourceSymbols), 
            baseSourceSymbols, 
            '0dx'
        ).
        
        converter:setBaseTarget(
            LENGTH(baseTargetSymbols),
            baseTargetSymbols,
            '0bx'
        ).
    END CONSTRUCTOR.
    
    METHOD PUBLIC CHARACTER convertNumber(n AS CHARACTER):
        RETURN converter:convertNumber(n, alwaysShiftPrefix).
    END METHOD.
    
    METHOD PUBLIC CHARACTER convertNumber(
        n AS CHARACTER,
        shiftPrefix AS LOGICAL
    ):
        RETURN converter:convertNumber(n, shiftPrefix).
    END METHOD.
END CLASS.
