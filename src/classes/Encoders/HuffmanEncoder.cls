USING PROGRESS.Lang.OBJECT.
USING Classes.DataStructures.BinTree.
USING Classes.BitWriter.BitWriter.

CLASS Classes.Encoders.HuffmanEncoder:
    DEFINE PRIVATE PROPERTY writer AS BitWriter GET. SET.
    DEFINE PUBLIC PROPERTY currentAlphabet AS LONGCHAR GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY translatedAlphabet AS LONGCHAR GET. PRIVATE SET.
    
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
    
    METHOD PUBLIC VOID encodeAlphabet(a AS LONGCHAR):
        clearEncoder().
        parseAlphabet(a).
        alphabetToTree().
        treeToEncodedAlphabet().
        translateAlphabet().
    END METHOD.
    
    METHOD PUBLIC VOID parseAlphabet(a AS LONGCHAR):
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE cidx AS CHARACTER.
        ASSIGN currentAlphabet = a.
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
    
    METHOD PUBLIC VOID translateAlphabet():
        DEFINE VARIABLE idx AS INT64.
        DEFINE VARIABLE cidx AS CHARACTER.
        
        ASSIGN translatedAlphabet = "".
        
        DO idx = 1 TO LENGTH(currentAlphabet):
            ASSIGN
                cidx = SUBSTRING(currentAlphabet, idx, 1).
            FIND FIRST encodedAlphabet
                WHERE encodedAlphabet.alphaChar = cidx.
            ASSIGN
                translatedAlphabet = translatedAlphabet + encodedAlphabet.binRep.
        END.
    END METHOD.
    
    METHOD PUBLIC MEMPTR writeInMemory():
        writer:clearWriter().
        writer:parseBitString(translatedAlphabet).
        RETURN writer:writeInMemory().
    END METHOD.
    
    METHOD PUBLIC VOID writeFile(filepath AS CHARACTER):
        writer:clearWriter().
        writer:parseBitString(translatedAlphabet).
        writer:writeFile(filepath).
    END METHOD.
    
    METHOD PRIVATE VOID addCharToAlphabet(a AS CHARACTER):
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
                alphabet.weight = 1
                alphabet.node = newNode.
         END.
         ELSE DO:
            ASSIGN
                alphabet.weight = alphabet.weight + 1.
         END.
    END METHOD.
    
    METHOD PUBLIC VOID clearEncoder():
        EMPTY TEMP-TABLE alphabet.
        EMPTY TEMP-TABLE encodedAlphabet.
        ASSIGN
            currentAlphabet = ""
            translatedAlphabet = "".
        writer:clearWriter().
    END METHOD.
END CLASS.
