package src;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;
#else
import js.Browser;
import js.html.*;
import js.html.webgl.*;
#end

// using macro black magic pulled from here:
// https://code.haxe.org/category/macros/include-file-next-to-module-file.html

class ShaderLoader {
    public static macro function getSource(filePath: String):ExprOf<String> {
        filePath = "shaders/" + filePath;

        // if the file exists, return its contents as a string expression
        if (FileSystem.exists(filePath)) {
            return macro $v{File.getContent(filePath)};
        }

        // otherwise throw a helpful error at compile-time
        throw("could not locate shader " + filePath + "!");

        return macro null;
    }

    #if !macro
    public static function loadShader(vertSource: String, fragSource: String): ShaderData {
        var context = Engine.context;

        inline function compileShader(type, source) {
            var shader = context.createShader(type);
            context.shaderSource(shader, source);
            context.compileShader(shader);

            if (!context.getShaderParameter(shader, GL.COMPILE_STATUS)) {
                throw("An error occurred compiling the shaders: " + context.getShaderInfoLog(shader));
                context.deleteShader(shader);
                return null;
            }

            return shader;
        }

        var vertexShader = compileShader(GL.VERTEX_SHADER, vertSource);
        var fragmentShader = compileShader(GL.FRAGMENT_SHADER, fragSource);

        var shaderProgram = context.createProgram();
        context.attachShader(shaderProgram, vertexShader);
        context.attachShader(shaderProgram, fragmentShader);
        context.linkProgram(shaderProgram);

        if (!context.getProgramParameter(shaderProgram, GL.LINK_STATUS)) {
            trace("Unable to initialize the shader program: " + context.getProgramInfoLog(shaderProgram));
            return null;
        }

        return {
            program: shaderProgram,

            attributes: [
                "vertexPosition" => context.getAttribLocation(shaderProgram, "aVertexPosition"),
                "vertexColor" => context.getAttribLocation(shaderProgram, "aVertexColor"),
            ],

            uniforms: [
                "projectionMatrix" => context.getUniformLocation(shaderProgram, "uProjectionMatrix"),
                "viewMatrix" => context.getUniformLocation(shaderProgram, "uViewMatrix"),
                "modelMatrix" => context.getUniformLocation(shaderProgram, "uModelMatrix"),
            ]
        };
    }
    #end
}
