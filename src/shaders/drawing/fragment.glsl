varying vec2 vUvs;

uniform float uTime;
uniform vec2 uResolution;

// Colors
vec3 white = vec3(1.0);
vec3 black = vec3(0.0);
vec3 red = vec3(1.0, 0.0, 0.0);
vec3 green = vec3(0.0, 1.0, 0.0);
vec3 blue = vec3(0.0, 0.0, 1.0);

void main() {
    vec3 color = black;
    vec2 pixelCoords = vUvs * 2.0 - 1.0;
    pixelCoords.x *= uResolution.x / uResolution.y;

    float d = length(pixelCoords);
    d = sin(d * 8.0 + uTime) / 8.0;
    d = abs(d);
    
    d = 0.01 / d;

    gl_FragColor = vec4(d, d, d, 1.0);
}