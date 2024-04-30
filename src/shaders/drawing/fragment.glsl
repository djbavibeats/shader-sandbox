/**
 * Varyings
 */
varying vec2 vUvs;

/**
 * Uniforms
 */
uniform float uTime;
uniform vec2 uResolution;

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;
    vec3 color = vec3(pixelCoords, 0.0);

    gl_FragColor = vec4(color, 1.0);
}