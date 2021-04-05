package src;

class Matrix {
    public var value: Array<Float> = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];

    public function new() { }

    public function identity(): Void {
        for (i in 0...16) {
            value[i] = i%5 == 0 ? 1 : 0;
        }
    }

    public function multiply(other: Matrix): Matrix {
        var result = new Matrix();

        inline function index(x: Int, y: Int): Int {
            return x + (y-1)*4;
        }

        var i = 0;
        for (y in 0...4) {
            for (x in 0...4) {
                result.value[i] =  value[index(1,y)]*other.value[index(x,1)];
                result.value[i] += value[index(2,y)]*other.value[index(x,2)];
                result.value[i] += value[index(3,y)]*other.value[index(x,3)];
                result.value[i] += value[index(4,y)]*other.value[index(x,4)];
                i += 1;
            }
        }

        return result;
    }

    // turns this matrix into a perspective projection matrix
    public function perspective(fov: Float, aspectRatio: Float, near: Float, far: Float): Void {
        var top = near * Math.tan(fov/2);
        var bottom = -top;
        var right = top * aspectRatio;
        var left = -right;

        value[0] = 2*near/(right-left);
        value[1] = 0;
        value[2] = 0;
        value[3] = 0;

        value[4] = 0;
        value[5] = 2*near/(top-bottom);
        value[6] = 0;
        value[7] = 0;

        value[8] = (right+left)/(right-left);
        value[9] = (top+bottom)/(top-bottom);
        value[10] = -1*(far+near)/(far-near);
        value[11] = -1;

        value[12] = 0;
        value[13] = 0;
        value[14] = -2*far*near/(far-near);
        value[15] = 0;
    }

    // translation, rotation, scale
    public function transform(tx: Float, ty: Float, tz: Float, rx: Float, ry: Float, rz: Float, sx: Float, sy: Float, sz: Float): Void {
        var ca = Math.cos(rx);
        var cb = Math.cos(ry);
        var cc = Math.cos(rz);
        var sa = Math.sin(rx);
        var sb = Math.sin(ry);
        var sc = Math.sin(rz);

        value[0] = ca*cb * sx;
        value[1] = sa*cb;
        value[2] = -sb;
        value[3] = 0;

        value[4] = ca*sb*sc - sa*cc;
        value[5] = (sa*sb*sc + ca*cc) * sy;
        value[6] = cb*sc;
        value[7] = 0;

        value[8] = ca*sb*cc + sa*sc;
        value[9] = sa*sb*cc - ca*sc;
        value[10] = cb*cc * sz;
        value[11] = 0;

        value[12] = tx;
        value[13] = ty;
        value[14] = tz;
        value[15] = 1;
    }

    public function view(eye1: Float, eye2: Float, eye3: Float, target1: Float, target2: Float, target3: Float, up1: Float, up2: Float, up3: Float) {
        var targetLength = Math.sqrt(Math.pow(eye1 - target1, 2) + Math.pow(eye2 - target2, 2) + Math.pow(eye3 - target3, 2));
        var z1 = (eye1 - target1) / targetLength;
        var z2 = (eye2 - target2) / targetLength;
        var z3 = (eye3 - target3) / targetLength;

        // cross up and z to get x
        var x1 = up2*z3 - up3*z2;
        var x2 = up3*z1 - up1*z3;
        var x3 = up1*z2 - up2*z1;

        // cross x and z to get y
        var y1 = x2*z3 - x3*z2;
        var y2 = x3*z1 - x1*z3;
        var y3 = x1*z2 - x2*z1;

        /*
        value[0] = x1
        value[1] = x2
        value[2] = x3
        value[3] = -1*(x1*eye1 + x2*eye2 + x3*eye3)

        value[4] = y1
        value[5] = y2
        value[6] = y3
        value[7] = -1*(y1*eye1 + y2*eye2 + y3*eye3)

        value[8] = z1
        value[9] = z2
        value[10] = z3
        value[11] = -1*(z1*eye1 + z2*eye2 + z3*eye3)

        value[12] = 0
        value[13] = 0
        value[14] = 0
        value[15] = 1
        */

        // transposed!

        value[0] = x1;
        value[4] = y1;
        value[8] = z1;
        value[12] = 0;

        value[1] = x2;
        value[5] = y2;
        value[9] = z2;
        value[13] = 0;

        value[2] = x3;
        value[6] = y3;
        value[10] = z3;
        value[14] = 0;

        value[3] = -1*(x1*eye1 + x2*eye2 + x3*eye3);
        value[7] = -1*(y1*eye1 + y2*eye2 + y3*eye3);
        value[11] = -1*(z1*eye1 + z2*eye2 + z3*eye3);
        value[15] = 1;
    }
}
