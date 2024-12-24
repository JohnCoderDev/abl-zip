# ABL ZIP

This is a small project that I meant to implement a ZIP DEFLATE algorithm
in the OpenEdge ABL. The version that I'm currently using is the `12.8`.

## How to use it

First off, you'll need to have some version of the OpenEdge ABL installed
in your computer, and this version must have support for classes.

In second place, you need to put the raw files in the `src` folder or the
compiled files in some place in your propath. It must follow the same folder
structure in the `src` folder.

For instance, let's say that *C:\Lib\OpenEdge\* is in your propath. Then
the `src` folder must be extracted in the following way: 
*C:\Lib\OpenEdge\classes\<class_directory>\<class_file>.cls*. If you want
to modify the structure of the folder, don't forget to edit all the `.cls`
files to match the new structure.

To use the ZIP DEFLATE algorithm you can write the following in your editor:

```
USING Classes.Zip.ZipDeflate.

DEFINE VARIABLE z AS ZipDeflate.

ASSIGN z = NEW ZipDeflate().

z:parseString('hello world').
z:writeFile(SESSION:TEMP-DIR + "test.zip").

DELETE OBJECT z.
```
