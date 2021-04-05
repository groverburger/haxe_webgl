package src;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;
#end

class ShaderLoader {
    public static macro function getShader(name: String):ExprOf<String> {
        var filePath = "shaders/" + name;

        // if the file exists, return its contents as a string expression
        if (FileSystem.exists(filePath)) {
            return macro $v{File.getContent(filePath)};
        }

        // otherwise throw a helpful error at compile-time
        throw("could not locate shader " + name + "!");

        return macro null;
    }
}
