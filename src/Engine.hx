package src;

import js.Browser;
import js.html.*;
import js.html.webgl.*;

class Engine {
    static var canvas: CanvasElement;
    static var context: RenderingContext;

    static function main() {
        canvas = cast(Browser.document.getElementById("mainCanvas"), CanvasElement);
        context = canvas.getContext("webgl", {antialias: false});

        canvas.addEventListener("mousedown", function() {
            canvas.requestPointerLock();
        });
        Input.setup();

        /***************************************************************************************
        * loading the shaders
        ***************************************************************************************/

        var vsSource = ShaderLoader.getShader("projection.vert");
        var fsSource = ShaderLoader.getShader("projection.frag");

        var shaderProgram = initShaderProgram(vsSource, fsSource);
        var programInfo = {
            program: shaderProgram,
            attribLocations: {
                vertexPosition: context.getAttribLocation(shaderProgram, "aVertexPosition"),
                vertexColor: context.getAttribLocation(shaderProgram, "aVertexColor"),
            },
            uniformLocations: {
                projectionMatrix: context.getUniformLocation(shaderProgram, "uProjectionMatrix"),
                viewMatrix: context.getUniformLocation(shaderProgram, "uViewMatrix"),
                modelMatrix: context.getUniformLocation(shaderProgram, "uModelMatrix"),
            }
        };

        /***************************************************************************************
        * manage resizing the window and canvas
        ***************************************************************************************/

        function resizeCanvas(): Void {
            canvas.width = Browser.window.innerWidth;
            canvas.height = Browser.window.innerHeight;
            context.viewport(0, 0, canvas.width, canvas.height);
        }
        resizeCanvas();
        Browser.window.addEventListener("resize", resizeCanvas);

        /***************************************************************************************
        * render loop
        ***************************************************************************************/

        var buffers = initBuffers();
        var cubeRotation = 0.0;
        var projectionMatrix = new Matrix();
        var modelMatrix = new Matrix();
        var viewMatrix = new Matrix();
        var camera = {
            position: [0.0, 0.0, 0.0],
            target: [0.0, -0.5, 1.0],
            yaw: 0.0, // side to side
            pitch: 0.0, // up and down
        };

        var lastTime: Float = null;

        function draw(time: Float): Void {
            if (lastTime == null) lastTime = time;
            var delta = (time - lastTime)/1000.0;
            lastTime = time;

            /***************************************************************************************
            * mouselook
            ***************************************************************************************/

            if (Browser.document.pointerLockElement == canvas) {
                camera.yaw -= Input.getMouseDeltaX()/500;
                camera.pitch += Input.getMouseDeltaY()/500;
            }
            camera.pitch = Math.max(Math.min(camera.pitch, Math.PI/2), Math.PI/-2);

            var sign = Math.cos(camera.pitch);
            if (sign > 0) {
                sign = 1;
            } else if (sign < 0) {
                sign = -1;
            } else {
                sign = 0;
            }

            // don't let cosPitch ever hit 0, because weird camera glitches will happen
            var cosPitch = sign*Math.max(Math.abs(Math.cos(camera.pitch)), 0.00001);

            /***************************************************************************************
            * movement
            ***************************************************************************************/

            var moveVector = [0.0, 0.0];
            var speed = 9;
            var dt = 1/60;

            // collect inputs
            if (Input.isKeyDown("w")) moveVector[1] += 1;
            if (Input.isKeyDown("a")) moveVector[0] -= 1;
            if (Input.isKeyDown("s")) moveVector[1] -= 1;
            if (Input.isKeyDown("d")) moveVector[0] += 1;
            if (Input.isKeyDown(" ")) {
                camera.position[1] += speed*dt;
            }
            if (Input.isKeyDown("shift")) {
                camera.position[1] -= speed*dt;
            }

            // do some trigonometry on the inputs to make movement relative to camera's yaw
            // also to make the player not move faster in diagonal directions
            if (moveVector[0] != 0.0 || moveVector[1] != 0.0) {
                var angle = Math.atan2(moveVector[1], moveVector[0]) - Math.PI/2;
                camera.position[0] += Math.sin(camera.yaw + angle)*speed*dt;
                camera.position[2] += Math.cos(camera.yaw + angle)*speed*dt;
            }

            // update projection matrix every frame so that aspect ratio can change
            // when the window size changes
            projectionMatrix.perspective(Math.PI/2, canvas.width/canvas.height, 0.1, 100);

            // spin the cube
            modelMatrix.transform(0,0,5, 0,cubeRotation,0, 1,1,1);

            // update the view matrix for the camera
            var pos = camera.position;
            var tgt = camera.target;
            tgt[0] = pos[0] + Math.sin(camera.yaw)*cosPitch;
            tgt[1] = pos[1] - Math.sin(camera.pitch);
            tgt[2] = pos[2] + Math.cos(camera.yaw)*cosPitch;
            viewMatrix.view(pos, tgt, [0.0,1.0,0.0]);

            /***************************************************************************************
            * draw stuff
            ***************************************************************************************/

            context.clearColor(0.25, 0.5, 1.0, 1.0);
            context.clearDepth(1.0);
            context.enable(GL.DEPTH_TEST);
            context.depthFunc(GL.LEQUAL);
            context.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

            var numComponents = 3;
            var type = GL.FLOAT;
            var normalize = false;
            var stride = 0;
            var offset = 0;
            context.bindBuffer(GL.ARRAY_BUFFER, buffers.position);
            context.vertexAttribPointer(programInfo.attribLocations.vertexPosition, numComponents, type, normalize, stride, offset);
            context.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);

            var numComponents = 4;
            var type = GL.FLOAT;
            var normalize = false;
            var stride = 0;
            var offset = 0;
            context.bindBuffer(GL.ARRAY_BUFFER, buffers.color);
            context.vertexAttribPointer(programInfo.attribLocations.vertexColor, numComponents, type, normalize, stride, offset);
            context.enableVertexAttribArray(programInfo.attribLocations.vertexColor);

            context.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffers.indices);
            context.useProgram(programInfo.program);
            context.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix.value);
            context.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix.value);
            context.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix.value);

            var vertexCount = 36;
            var type = GL.UNSIGNED_SHORT;
            var offset = 0;
            context.drawElements(GL.TRIANGLES, vertexCount, type, offset);

            cubeRotation += 1/60;
            Input.update();
            Browser.window.requestAnimationFrame(draw);
        }

        Browser.window.requestAnimationFrame(draw);
    }

    static function initBuffers() {
        var positionBuffer = context.createBuffer();
        context.bindBuffer(GL.ARRAY_BUFFER, positionBuffer);

        var positions = [
            -1.0, -1.0,  1.0,
            1.0, -1.0,  1.0,
            1.0,  1.0,  1.0,
            -1.0,  1.0,  1.0,

            -1.0, -1.0, -1.0,
            -1.0,  1.0, -1.0,
            1.0,  1.0, -1.0,
            1.0, -1.0, -1.0,

            -1.0,  1.0, -1.0,
            -1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0, -1.0,

            -1.0, -1.0, -1.0,
            1.0, -1.0, -1.0,
            1.0, -1.0,  1.0,
            -1.0, -1.0,  1.0,

            1.0, -1.0, -1.0,
            1.0,  1.0, -1.0,
            1.0,  1.0,  1.0,
            1.0, -1.0,  1.0,

            -1.0, -1.0, -1.0,
            -1.0, -1.0,  1.0,
            -1.0,  1.0,  1.0,
            -1.0,  1.0, -1.0,
        ];

        context.bufferData(GL.ARRAY_BUFFER, new js.lib.Float32Array(positions), GL.STATIC_DRAW);

        var faceColors = [
            [1.0,  1.0,  1.0,  1.0],
            [1.0,  0.0,  0.0,  1.0],
            [0.0,  1.0,  0.0,  1.0],
            [0.0,  0.0,  1.0,  1.0],
            [1.0,  1.0,  0.0,  1.0],
            [1.0,  0.0,  1.0,  1.0],
        ];

        var colors = [];

        for (i in 0...4) {
            for (c in faceColors) {
                colors = colors.concat(c);
            }
        }

        var colorBuffer = context.createBuffer();
        context.bindBuffer(GL.ARRAY_BUFFER, colorBuffer);
        context.bufferData(GL.ARRAY_BUFFER, new js.lib.Float32Array(colors), GL.STATIC_DRAW);

        var indexBuffer = context.createBuffer();
        context.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);

        var indices = [
            0,  1,  2,      0,  2,  3,
            4,  5,  6,      4,  6,  7,
            8,  9,  10,     8,  10, 11,
            12, 13, 14,     12, 14, 15,
            16, 17, 18,     16, 18, 19,
            20, 21, 22,     20, 22, 23,
        ];

        context.bufferData(GL.ELEMENT_ARRAY_BUFFER, new js.lib.Uint16Array(indices), GL.STATIC_DRAW);

        return {
            position: positionBuffer,
            color: colorBuffer,
            indices: indexBuffer,
        };
    }

    static function initShaderProgram(vsSource, fsSource) {
        var vertexShader = loadShader(GL.VERTEX_SHADER, vsSource);
        var fragmentShader = loadShader(GL.FRAGMENT_SHADER, fsSource);

        var shaderProgram = context.createProgram();
        context.attachShader(shaderProgram, vertexShader);
        context.attachShader(shaderProgram, fragmentShader);
        context.linkProgram(shaderProgram);

        if (!context.getProgramParameter(shaderProgram, GL.LINK_STATUS)) {
            trace("Unable to initialize the shader program: " + context.getProgramInfoLog(shaderProgram));
            return null;
        }

        return shaderProgram;
    }

    static function loadShader(type, source) {
        var shader = context.createShader(type);

        context.shaderSource(shader, source);
        context.compileShader(shader);
        if (!context.getShaderParameter(shader, GL.COMPILE_STATUS)) {
            trace("An error occurred compiling the shaders: " + context.getShaderInfoLog(shader));
            context.deleteShader(shader);
            return null;
        }

        return shader;
    }
}
