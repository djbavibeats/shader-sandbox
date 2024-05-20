varying vec2 vUvs;

uniform float uTime;

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}
void main() {

    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);

    vUvs = uv;
}