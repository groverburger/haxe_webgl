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

    // view matrix, just a lookAt function
    public function view(eye: Array<Float>, target: Array<Float>, up: Array<Float>) {
        inline function vectorNormalize(vector: Array<Float>): Array<Float> {
            var len = Math.sqrt(vector[0]*vector[0] + vector[1]*vector[1] + vector[2]*vector[2]);
            return [vector[0] / len, vector[1] / len, vector[2] / len];
        }

        inline function vectorCrossProduct(a: Array<Float>, b: Array<Float>): Array<Float> {
            return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]];
        }

        inline function vectorDotProduct(a: Array<Float>, b: Array<Float>): Float {
            return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
        }

        var z = vectorNormalize([eye[0] - target[0], eye[1] - target[1], eye[2] - target[2]]);
        var x = vectorNormalize(vectorCrossProduct(up, z));
        var y = vectorCrossProduct(z, x);

        value[0] = x[0];
        value[1] = y[0];
        value[2] = z[0];
        value[3] = 0;

        value[4] = x[1];
        value[5] = y[1];
        value[6] = z[1];
        value[7] = 0;

        value[8] = x[2];
        value[9] = y[2];
        value[10] = z[2];
        value[11] = 0;

        value[12] = -1*vectorDotProduct(x, eye);
        value[13] = -1*vectorDotProduct(y, eye);
        value[14] = -1*vectorDotProduct(z, eye);
        value[15] = 1;
    }
}
