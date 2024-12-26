USING PROGRESS.Lang.OBJECT.
USING Classes.DataStructures.BinTree.
USING Classes.BitWriter.BitWriter.

CLASS Classes.Encoders.HuffmanEncoder:
    DEFINE PRIVATE PROPERTY writer AS BitWriter GET. SET.
    DEFINE PUBLIC PROPERTY currentPhrase AS LONGCHAR GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY translatedPhrase AS LONGCHAR GET. PRIVATE SET.
    
    DEFINE PRIVATE TEMP-TABLE alphabet
        FIELD alphaChar AS CHARACTER
        FIELD weight AS INT64
        FIELD node AS OBJECT
        INDEX idxWeight AS PRIMARY 
            weight ASCENDING.
        
    DEFINE PRIVATE TEMP-TABLE encodedAlphabet
        FIELD alphaChar AS CHARACTER
        FIELD binRep AS CHARACTER
        INDEX idxChar AS UNIQUE PRIMARY 
            alphaChar ASCENDING 
            binRep ASCENDING.
    
    CONSTRUCTOR HuffmanEncoder():
        ASSIGN writer = NEW BitWriter().
        clearEncoder().
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID encodeAlphabetFromPhrase(a AS LONGCHAR):
        clearEncoder().
        parsePhrase(a).
        encodeCurrentAlphabet().
        translatePhrase().
    END METHOD.
    
    METHOD PUBLIC VOID encodeCurrentAlphabet():
        alphabetToTree().
        treeToEncodedAlphabet().
    END METHOD.
    
    METHOD PUBLIC VOID parsePhrase(a AS LONGCHAR):
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE cidx AS CHARACTER.
        
        setCurrentPhrase(a).
        DO idx = 1 TO LENGTH(a):
            ASSIGN cidx = SUBSTRING(a, idx, 1).
            addCharToAlphabet(cidx).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID alphabetToTree():
        DEFINE VARIABLE firstWeight AS INT64.
        DEFINE VARIABLE firstChar AS CHARACTER.
        DEFINE VARIABLE firstNode AS BinTree.
        DEFINE VARIABLE secondWeight AS INT64.
        DEFINE VARIABLE secondChar AS CHARACTER.
        DEFINE VARIABLE secondNode AS BinTree.
        DEFINE VARIABLE resultWeight AS INT64.
        DEFINE VARIABLE resultChar AS CHARACTER.
        DEFINE VARIABLE resultNode AS BinTree.
        
        REPEAT:
            FIND FIRST alphabet.
            ASSIGN
                firstChar = alphabet.alphaChar
                firstWeight = alphabet.weight
                firstNode = CAST(alphabet.node, BinTree).
            
            FIND NEXT alphabet NO-ERROR.
            IF NOT AVAILABLE alphabet THEN LEAVE.
            ASSIGN
                secondChar = alphabet.alphaChar
                secondWeight = alphabet.weight
                secondNode = CAST(alphabet.node, BinTree).
           
            ASSIGN
                resultChar = firstChar + secondChar
                resultWeight = firstWeight + secondWeight
                resultNode = NEW BinTree()
                resultNode:nodeValue = resultChar
                resultNode:leftWeight = 0 
                resultNode:rightWeight = 1.
           
            resultNode:addChilds(firstNode, secondNode).
           
            DELETE alphabet.
            FIND FIRST alphabet.
            DELETE alphabet.
            
            CREATE alphabet.
            ASSIGN
                alphabet.alphaChar = resultChar
                alphabet.weight = resultWeight
                alphabet.node = resultNode.
       END.
    END METHOD.
    
    METHOD PUBLIC VOID treeToEncodedAlphabet():
        FIND FIRST alphabet.
        treeToEncodedAlphabet(CAST(alphabet.node, BinTree), "").
    END METHOD.
    
    METHOD PRIVATE VOID treeToEncodedAlphabet(
        node AS BinTree,
        currentBinRep AS CHARACTER
    ):
                
        IF node:isLeaf() THEN DO:
            CREATE encodedAlphabet.
            ASSIGN
                encodedAlphabet.alphaChar = node:nodeValue
                encodedAlphabet.binRep = currentBinRep.
        END.
        ELSE DO:
            treeToEncodedAlphabet(
                node:leftNode,
                currentBinRep + STRING(node:leftWeight)
            ).
            treeToEncodedAlphabet(
                node:rightNode,
                currentBinRep + STRING(node:rightWeight)
            ).
        END.
    END METHOD.
    
    METHOD PUBLIC VOID setCurrentPhrase(a AS LONGCHAR):
        ASSIGN currentPhrase = a.
    END METHOD.
    
    METHOD PUBLIC VOID translatePhrase():
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE cidx AS CHARACTER.
        
        ASSIGN translatedPhrase = "".
        
        DO idx = 1 TO LENGTH(currentPhrase):
            ASSIGN
                cidx = SUBSTRING(currentPhrase, idx, 1).
            FIND FIRST encodedAlphabet
                WHERE encodedAlphabet.alphaChar = cidx.
            ASSIGN
                translatedPhrase = translatedPhrase + encodedAlphabet.binRep.
        END.
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
    
    METHOD PUBLIC VOID addCharToAlphabet(a AS CHARACTER, w AS INT64):
        IF LENGTH(a) <> 1 THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'this method only supports one char at a time',
                -200
            ).
        END.
        
        FIND FIRST alphabet
            WHERE alphabet.alphaChar = a
            NO-ERROR.
        
        IF NOT AVAILABLE alphabet THEN DO:
            DEFINE VARIABLE newNode AS BinTree.
            CREATE alphabet.
            ASSIGN
                newNode = NEW BinTree()
                newNode:nodeValue = a
                alphabet.alphaChar = a
                alphabet.weight = IF w = -1 
                    THEN 1 
                    ELSE w
                alphabet.node = newNode.
         END.
         ELSE DO:
            ASSIGN
                alphabet.weight = IF w = -1 
                    THEN alphabet.weight + 1 
                    ELSE w.
         END.
    END METHOD.
    
    METHOD PUBLIC VOID addCharToAlphabet(a AS CHARACTER):
        addCharToAlphabet(a, -1).
    END METHOD.
    
    
    METHOD PUBLIC VOID addCharToEncodedAlphabet(
        a AS CHARACTER,
        binaryRep AS CHARACTER
    ):
        IF CAN-FIND(
            FIRST encodedAlphabet
            WHERE encodedAlphabet.binRep = binaryRep
                AND encodedAlphabet.alphaChar <> a
        ) THEN DO:
            UNDO, THROW NEW PROGRESS.Lang.AppError(
                'binary representation already taken by char `' 
                + encodedAlphabet.alphaChar + '`',
                -202
            ).    
        END.
        
        FIND FIRST encodedAlphabet 
            WHERE encodedAlphabet.alphaChar = a
            NO-ERROR.
        
        IF NOT AVAILABLE encodedAlphabet THEN DO:
            CREATE encodedAlphabet.
        END.
        
        ASSIGN
            encodedAlphabet.alphaChar = a
            encodedAlphabet.binRep = binaryRep.
    END METHOD.
    
    METHOD PUBLIC HANDLE getEncodedAlphabetTableBuffer():
        RETURN TEMP-TABLE encodedAlphabet:DEFAULT-BUFFER-HANDLE.            
    END METHOD.

    METHOD PUBLIC VOID showEncodedTable():
        FOR EACH encodedAlphabet:
            DISPLAY encodedAlphabet
                WITH SCROLLABLE.
        END.
    END METHOD.
    
    METHOD PUBLIC VOID clearEncoder():
        EMPTY TEMP-TABLE alphabet.
        EMPTY TEMP-TABLE encodedAlphabet.
        ASSIGN
            currentPhrase = ""
            translatedPhrase = "".
        writer:clearWriter().
    END METHOD.
END CLASS.
