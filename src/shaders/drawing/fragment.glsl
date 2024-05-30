varying vec2 vUvs;

uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uTime;

#define PI 3.14159265359

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

/**
*   Transform Functions
*/
mat3 rotateX(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
  float s = sin(angle);
  float c = cos(angle);

  return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateZ(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

/**
*   SDFs
*/
float sdfSphere(vec3 pos, float rad) {
  return length(pos) - rad;
}

float sdfBox(vec3 pos, vec3 box) {
  vec3 q = abs(pos) - box;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfTorus(vec3 pos, vec2 torus) {
  vec2 q = vec2(length(pos.xz) - torus.x, pos.y);
  return length(q) - torus.y;
}

float sdfPlane(vec3 pos) {
  return pos.y;
}

struct MaterialData {
  vec3 color;
  float dist;
};

vec3 RED = vec3(1.0, 0.0, 0.0);
vec3 BLUE = vec3(0.0, 0.0, 1.0);
vec3 GREEN = vec3(0.0, 1.0, 0.0);
vec3 GRAY = vec3(0.5);
vec3 WHITE = vec3(1.0);

// Calculates the overall SDF for the scene.
MaterialData map(vec3 pos) {
  // Result 
  // Initialze the result material with the first object
  // Result contains MaterialData for the entire scene
  MaterialData result = MaterialData(
    GRAY,
    sdfPlane(pos - vec3(0.0, -2.0, 0.0))
  );

  float dist;

  // Draw the first box
  dist = sdfBox(pos - vec3(-2.0, -0.85, 5.0), vec3(1.0));
  // If the point is inside the first box sdf, paint it red, else stay the same
  if (dist < result.dist) {
    result.color = RED;
  }
  result.dist = min(result.dist, dist);

  dist = sdfBox(pos - vec3(2.0, -0.85, 5.0), vec3(1.0));
  // If the point is inside the second box sdf, paint it blue else stay the same
  if (dist < result.dist) {
    result.color = BLUE;
  }
  result.dist = min(result.dist, dist);

  dist = sdfTorus(
    (pos - vec3(0.0, 1.85, 5.0)) * rotateX(uTime)
    , vec2(1.0, 0.4)
  );
  // If the point is inside the first torus sdf, paint it green else stay the same
  if (dist < result.dist) {
    result.color = GREEN;
  }
  result.dist = min(result.dist, dist);

  return result;
}

// Performs sphere tracing for the scene.
// Returns a color for the current point.
const int NUM_STEPS  = 256;
const float MAX_DIST = 1000.0;

vec3 RayMarch(vec3 cameraOrigin, vec3 cameraDir) {
  vec3 pos;

  // Just initializing, no real material info here
  MaterialData material = MaterialData(vec3(0.0), 0.0);

  for (int i = 0; i < NUM_STEPS; ++i) {
    pos = cameraOrigin + material.dist * cameraDir;

    MaterialData result = map(pos);

    // Case 1: distToScene < 0, intersected scene.
    // BREAK
    if (result.dist < 0.001) {
      // Break and just return the current color
      break;
    }
    material.dist += result.dist;
    material.color = result.color;

    // Case 2: dist > MAX_DIST, out of the scene entirely.
    // This happens when we don't hit anything
    // So this is basically the undefined background, this point is out of bounds
    // RETURN
    if (material.dist > MAX_DIST) {
      return vec3(0.0);
    }

    // Case 3: Loop around, do nothing.
  }

  // Finished loop
  return vec3(material.color);
}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;


    // Camera Origin
    vec3 rayOrigin = vec3(0.0, 0.0, 0.0);

    // Camera Direction
    vec3 rayDir = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));

    vec3 color = RayMarch(rayOrigin, rayDir);

    gl_FragColor = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}