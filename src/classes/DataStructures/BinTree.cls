USING Classes.DataStructures.BinTree.

CLASS Classes.DataStructures.BinTree:
    DEFINE PUBLIC PROPERTY parentNode AS BinTree GET. SET.
    DEFINE PUBLIC PROPERTY leftNode AS BinTree GET. SET.
    DEFINE PUBLIC PROPERTY rightNode AS BinTree GET. SET.
    DEFINE PUBLIC PROPERTY leftWeight AS INT64 GET. SET.
    DEFINE PUBLIC PROPERTY rightWeight AS INT64 GET. SET.
    DEFINE PUBLIC PROPERTY nodeValue AS CHARACTE GET. SET.
    
    CONSTRUCTOR BinTree():
        ASSIGN
            parentNode = ?
            leftNode = ?
            rightNode = ?
            leftWeight = 0
            rightWeight = 0.
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID addChilds(
        leftChild AS BinTree,
        rightChild AS BinTree
    ):
        ASSIGN
            leftNode = leftChild
            rightNode = rightChild
            leftNode:parentNode = THIS-OBJECT
            rightNode:parentNode = THIS-OBJECT.
    END METHOD.
    
    METHOD PUBLIC LOGICAL isLeaf():
        RETURN (leftNode = ?) AND (rightNode = ?).
    END METHOD.
    
    METHOD PUBLIC LOGICAL isRoot():
        RETURN parentNode = ?.
    END METHOD.
END CLASS.
