package src;

import js.Browser;
import js.html.*;
import js.html.webgl.*;

class Engine {
    static var canvas: CanvasElement;
    public static var shaderData: ShaderData;
    public static var context: RenderingContext;

    static function main() {
        canvas = cast(Browser.document.getElementById("mainCanvas"), CanvasElement);
        context = canvas.getContext("webgl", {antialias: false});

        // setup input
        canvas.addEventListener("mousedown", function() {
            canvas.requestPointerLock();
        });
        Input.setup();

        // manage resizing the window and canvas
        function resizeCanvas(): Void {
            canvas.width = Browser.window.innerWidth;
            canvas.height = Browser.window.innerHeight;
            context.viewport(0, 0, canvas.width, canvas.height);
        }
        resizeCanvas();
        Browser.window.addEventListener("resize", resizeCanvas);

        ////////////////////////////////////////////////////////////////////////////////
        // load the shader
        ////////////////////////////////////////////////////////////////////////////////

        shaderData = ShaderLoader.loadShader(
            ShaderLoader.getSource("projection.vert"),
            ShaderLoader.getSource("projection.frag")
        );
        context.useProgram(shaderData.program);

        ////////////////////////////////////////////////////////////////////////////////
        // create the cube
        ////////////////////////////////////////////////////////////////////////////////

        var positionData = [
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

        var faceColors = [
            [1.0,  1.0,  1.0,  1.0],
            [1.0,  0.0,  0.0,  1.0],
            [0.0,  1.0,  0.0,  1.0],
            [0.0,  0.0,  1.0,  1.0],
            [1.0,  1.0,  0.0,  1.0],
            [1.0,  0.0,  1.0,  1.0],
        ];
        var colorData = [];
        for (i in 0...4) {
            for (c in faceColors) {
                colorData = colorData.concat(c);
            }
        }

        var indexData = [
            0,  1,  2,      0,  2,  3,
            4,  5,  6,      4,  6,  7,
            8,  9,  10,     8,  10, 11,
            12, 13, 14,     12, 14, 15,
            16, 17, 18,     16, 18, 19,
            20, 21, 22,     20, 22, 23,
        ];

        var cube = new Mesh(positionData, colorData, indexData);

        ////////////////////////////////////////////////////////////////////////////////
        // render loop
        ////////////////////////////////////////////////////////////////////////////////

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

            ////////////////////////////////////////////////////////////////////////////////
            // mouselook
            ////////////////////////////////////////////////////////////////////////////////

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

            ////////////////////////////////////////////////////////////////////////////////
            // movement
            ////////////////////////////////////////////////////////////////////////////////

            var moveVector = [0.0, 0.0];
            var speed = 9;

            // collect inputs
            if (Input.isKeyDown("w")) moveVector[1] += 1;
            if (Input.isKeyDown("a")) moveVector[0] -= 1;
            if (Input.isKeyDown("s")) moveVector[1] -= 1;
            if (Input.isKeyDown("d")) moveVector[0] += 1;
            if (Input.isKeyDown(" ")) {
                camera.position[1] += speed*delta;
            }
            if (Input.isKeyDown("shift")) {
                camera.position[1] -= speed*delta;
            }

            // do some trigonometry on the inputs to make movement relative to camera's yaw
            // also to make the player not move faster in diagonal directions
            if (moveVector[0] != 0.0 || moveVector[1] != 0.0) {
                var angle = Math.atan2(moveVector[1], moveVector[0]) - Math.PI/2;
                camera.position[0] += Math.sin(camera.yaw + angle)*speed*delta;
                camera.position[2] += Math.cos(camera.yaw + angle)*speed*delta;
            }

            // update projection matrix every frame so that aspect ratio can change
            // when the window size changes
            projectionMatrix.perspective(Math.PI/2, canvas.width/canvas.height, 0.1, 100);

            // spin the cube
            cubeRotation += delta;
            modelMatrix.transform(0,0,5, 0,cubeRotation,0, 1,1,1);

            // update the view matrix for the camera
            var pos = camera.position;
            var tgt = camera.target;
            tgt[0] = pos[0] + Math.sin(camera.yaw)*cosPitch;
            tgt[1] = pos[1] - Math.sin(camera.pitch);
            tgt[2] = pos[2] + Math.cos(camera.yaw)*cosPitch;
            viewMatrix.view(pos, tgt, [0.0,1.0,0.0]);

            // send the matrices to the shader
            context.uniformMatrix4fv(shaderData.uniforms["projectionMatrix"], false, projectionMatrix.value);
            context.uniformMatrix4fv(shaderData.uniforms["modelMatrix"], false, modelMatrix.value);
            context.uniformMatrix4fv(shaderData.uniforms["viewMatrix"], false, viewMatrix.value);

            ////////////////////////////////////////////////////////////////////////////////
            // draw stuff
            ////////////////////////////////////////////////////////////////////////////////

            // clear the screen
            context.clearColor(0.25, 0.5, 1.0, 1.0);
            context.clearDepth(1.0);
            context.enable(GL.DEPTH_TEST);
            context.depthFunc(GL.LEQUAL);
            context.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

            cube.draw();

            Input.update();
            Browser.window.requestAnimationFrame(draw);
        }

        Browser.window.requestAnimationFrame(draw);
    }
}
