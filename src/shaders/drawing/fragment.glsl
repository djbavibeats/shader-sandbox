/**
 * Varyings
 */
varying vec2 vUvs;

/**
 * Uniforms
 */
uniform float uTime;
uniform vec2 uResolution;
uniform sampler2D uDiffuse;

/**
 * Colors
 */
vec3 white = vec3(1.0);
vec3 black = vec3(0.0);
vec3 darkgrey = vec3(0.15, 0.15, 0.135);
vec3 red = vec3(1.0, 0.0, 0.0);

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

vec3 drawGrid(vec3 color, vec2 spacing) {
    vec2 cell = abs(fract(vUvs * uResolution / spacing) - 0.5);
    float line = 1.0 - max(cell.x, cell.y) * 2.0;
    color = mix(black, color, smoothstep(0.00, 0.05, line));

    return color;
}

float sdfCircle(vec2 pos, vec2 spacing, float count, float radius, float time) {
    float d = length(pos / spacing);
    if (d < radius) {
        d = abs(sin(d * count + time * 5.0)); 
        return d;
    }
    return 0.0;
}

float hash(vec2 v) {
    float t = dot(v, vec2(36.5323, 73.945));
    return sin(t);
}

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

mat2 rotate2D( float angle ) {
    mat2 t = mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    );
    return t;
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

float opIntersection(float d1, float d2) {
    return max(d1, d2);
}

float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

vec3 drawBackground (vec3 color) {
    vec3 gradient = mix(
        vec3(0.50196, 0.81569, 0.78039),
        vec3(0.87843, 0.76470, 0.98823),
        smoothstep(0.0, 1.0, pow(vUvs.x * vUvs.y, 1.0))
    );
    return gradient;
}
void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;
    vec2 spacing = vec2(50.0, 50.0);

    float time = uTime * 0.75;
    
    vec3 color = white;
    color = drawBackground(color);
    float result = 0.0;
    float NUM_CIRCLES = 10.0;
    for (float i = 0.0; i < NUM_CIRCLES; i += 1.0) {

        vec2 offset = vec2(i * 150.0 - (uResolution.x / 1.1), i * 50.0 - (uResolution.y / 1.8)) * hash(vec2(i));
        float size = fract(0.18 * (i + 5.5)) * 2.25;
        float opacity = remap(sin(hash(vec2(i) + time * 0.01)), -1.0, 1.0, 0.5, 1.0);
        vec2 boxPos = pixelCoords;
        boxPos = rotate2D(3.14159 - time * 0.1 * i) * boxPos;
        boxPos.x += sin(hash(vec2(i+0.5)) * uTime) * 50.0;
        boxPos.y += cos(hash(vec2(i+0.5)) * uTime) * 75.0;

        float circle = opacity * abs(sdfCircle(boxPos - offset, spacing, 16.0, size, time ));
        color = mix(color, vec3(0.72549, 0.78431, 0.90196), smoothstep(0.0, 1.0, circle));
    }
    

    gl_FragColor = vec4(color, 1.0);
}