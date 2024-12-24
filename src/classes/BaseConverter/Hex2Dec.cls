USING Classes.BaseConverter.BaseConverter.

CLASS Classes.BaseConverter.Hex2Dec:
    DEFINE PRIVATE PROPERTY converter AS BaseConverter GET. SET.
    DEFINE PRIVATE PROPERTY baseTargetSymbols AS CHARACTER GET. SET.
    DEFINE PRIVATE PROPERTY baseSourceSymbols AS CHARACTER GET. SET.
    DEFINE PUBLIC PROPERTY alwaysShiftPrefix AS LOGICAL GET. SET.
    
    CONSTRUCTOR Hex2Dec():
        ASSIGN
            converter = NEW BaseConverter()
            alwaysShiftPrefix = FALSE
            baseSourceSymbols = '0123456789abcdef'
            baseTargetSymbols = '0123456789'.
        
        converter:setBaseSource(
            LENGTH(baseSourceSymbols), 
            baseSourceSymbols, 
            '0hx'
        ).
        
        converter:setBaseTarget(
            LENGTH(baseTargetSymbols),
            baseTargetSymbols,
            '0dx'
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
