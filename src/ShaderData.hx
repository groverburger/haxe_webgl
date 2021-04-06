package src;

import js.Browser;
import js.html.*;
import js.html.webgl.*;

typedef ShaderData = {
    program: Program,
    attributes: Map<String, Int>,
    uniforms: Map<String, UniformLocation>,
};
