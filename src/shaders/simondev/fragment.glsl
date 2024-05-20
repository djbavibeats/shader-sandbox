
varying vec2 vUvs;

uniform float uTime;
uniform vec2 uResolution;

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

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

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdfBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}


float sdfTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sdfPlane(vec3 p) {
    return p.y;
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

// The map function calculates the overall SDF.
// 1. Set the position of the object
// 2. Tranform the rotation
MaterialData map(vec3 pos) {
    MaterialData result = MaterialData(
        GRAY, sdfPlane(pos - vec3(0.0, -2.0, 0.0))
    );

    float dist;

    dist = sdfBox(pos - vec3(-2.0, -0.85, 5.0), vec3(1.0));
    result.color = dist < result.dist ? RED : result.color;
    result.dist = min(result.dist, dist);

    dist = sdfBox(pos - vec3(2.0, -0.85, 5.0), vec3(1.0));
    result.color = dist < result.dist ? BLUE : result.color;
    result.dist = min(result.dist, dist);

    dist = sdfBox(pos - vec3(2.0, 1.0, 50.0 + sin(uTime) * 25.0), vec3(2.0));
    result.color = dist < result.dist ? BLUE : result.color;
    result.dist = min(result.dist, dist);

    return result;

}

vec3 CalculateNormal(vec3 pos) {
    const float EPS = 0.0001;
    vec3 n = vec3(
        map(pos + vec3(EPS, 0.0, 0.0)).dist - map(pos - vec3(EPS, 0.0, 0.0)).dist,
        map(pos + vec3(0.0, EPS, 0.0)).dist - map(pos - vec3(0.0, EPS, 0.0)).dist,
        map(pos + vec3(0.0, 0.0, EPS)).dist - map(pos - vec3(0.0, 0.0, EPS)).dist
    );
    return normalize(n);
}

vec3 CalculateLighting(vec3 pos, vec3 normal, vec3 lightColor, vec3 lightDir) {
    float dp = saturate(dot(normal, lightDir));
    return lightColor * dp;
}

float CalculateShadow(vec3 pos, vec3 lightDir) {
    float d = 0.01;
    for (int i = 0; i < 64; ++i) {
        float distToScene = map(pos + lightDir * d).dist;

        if (distToScene < 0.001) {
            return 0.0;
        }

        d += distToScene;
    }

    return 1.0;
}

float CalculateAO(vec3 pos, vec3 normal) {
    float ao = 0.0;
    float stepSize = 0.1;

    for (float i = 0.0; i < 5.0; ++i) {
        float distFactor = 1.0 / pow(2.0, i);

        ao += distFactor * (i * stepSize - map(pos + normal * i * stepSize).dist);
    }

    return 1.0 - ao;
}

const int NUM_STEPS = 256;
const float MAX_DIST = 1000.0;

// Perform sphere tracing for the scene.
vec3 RayMarch(vec3 cameraOrigin, vec3 cameraDir) {

    vec3 pos;
    MaterialData material = MaterialData(vec3(0.0), 0.0);

    vec3 skyColor = vec3(0.55, 0.6, 1.0);

    for (int i = 0; i < NUM_STEPS; ++i) {
        pos = cameraOrigin + material.dist * cameraDir;

        MaterialData result = map(pos);

        // Case 1: distToScene < 0, intersected scene
        // BREAK
        if (result.dist < 0.001) {
            break;
        }
        material.dist += result.dist;
        material.color = result.color;

        // Case 2: dist > MAX_DIST, out of the scene entirely
        // RETURN
        if (material.dist > MAX_DIST) {
            return skyColor;
        }

        // Case 3: Loop around, in reality, do nothing
    }

    // Finished loop

    vec3 lightDir = normalize(vec3(1.0, 2.0, -1.0));
    vec3 lightColor = WHITE;
    vec3 normal = CalculateNormal(pos);
    float shadowed = CalculateShadow(pos, lightDir);
    vec3 lighting = CalculateLighting(pos, normal, lightColor, lightDir);\
    lighting *= shadowed;
    vec3 color = material.color * lighting;

    float fogFactor = 1.0 - exp(-pos.z * 0.01);
    color = mix(color, skyColor, fogFactor);

    return color;

}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;

    vec3 rayDir = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));
    vec3 rayOrigin = vec3(0.0);

    vec3 color = RayMarch(rayOrigin, rayDir);

    gl_FragColor = vec4(color, 1.0);
}

// Todo
// 1. Change sky to a gradient
// 2. Add more objects and combine them using a Union function
// 3. Add noise to the objects
// 4. Add phong to the lighting model
// 5. Change specular variables for each object
// 6. Define a camera matrix and move the camera around the scene