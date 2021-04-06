package src;

import js.html.webgl.*;

class Mesh {
    var positionBuffer: Buffer;
    var colorBuffer: Buffer;
    var indexBuffer: Buffer;

    public function new(positionData: Array<Float>, colorData: Array<Float>, indexData: Array<Int>) {
        var context = Engine.context;

        positionBuffer = context.createBuffer();
        context.bindBuffer(GL.ARRAY_BUFFER, positionBuffer);
        context.bufferData(GL.ARRAY_BUFFER, new js.lib.Float32Array(positionData), GL.STATIC_DRAW);

        colorBuffer = context.createBuffer();
        context.bindBuffer(GL.ARRAY_BUFFER, colorBuffer);
        context.bufferData(GL.ARRAY_BUFFER, new js.lib.Float32Array(colorData), GL.STATIC_DRAW);

        indexBuffer = context.createBuffer();
        context.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        context.bufferData(GL.ELEMENT_ARRAY_BUFFER, new js.lib.Uint16Array(indexData), GL.STATIC_DRAW);
    }

    public function draw() {
        var context = Engine.context;

        // vertexAttribPointer arguments:
        // pointer, amount in a row, type, normalized, stride, offset
        // stride and offset are in bytes
        // stride is the distance between start of one attrib and the next
        // offset is the offset of the first attrib in the array

        context.bindBuffer(GL.ARRAY_BUFFER, positionBuffer);
        context.vertexAttribPointer(Engine.shaderData.attributes["vertexPosition"], 3, GL.FLOAT, false, 0, 0);
        context.enableVertexAttribArray(Engine.shaderData.attributes["vertexPosition"]);

        context.bindBuffer(GL.ARRAY_BUFFER, colorBuffer);
        context.vertexAttribPointer(Engine.shaderData.attributes["vertexColor"], 4, GL.FLOAT, false, 0, 0);
        context.enableVertexAttribArray(Engine.shaderData.attributes["vertexColor"]);

        context.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        context.drawElements(GL.TRIANGLES, 36, GL.UNSIGNED_SHORT, 0);
    }
}
