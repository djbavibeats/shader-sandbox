varying vec2 vUvs;
uniform vec2 uResolution;
uniform float uTime;

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

float sdfSphere(vec3 pos, float rad) {
  return length(pos) - rad;
}

float sdfPlane(vec3 pos) {
    return pos.y;
}

float sdfBox(vec3 pos, vec3 box) {
    vec3 q = abs(pos) - box;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

struct MaterialData {
    vec3 color;
    float dist;
};

vec3 RED    = vec3(1.0, 0.0, 0.0);
vec3 GREEN  = vec3(0.0, 1.0, 0.0);
vec3 BLUE   = vec3(0.0, 0.0, 1.0);
vec3 GRAY   = vec3(0.5, 0.5, 0.5);
vec3 WHITE  = vec3(1.0, 1.0, 1.0);
vec3 BLACK  = vec3(0.0, 0.0, 0.0);
vec3 SKY    = vec3(0.0, 0.3, 0.6);
vec3 GROUND = vec3(0.6, 0.3, 0.1);

MaterialData map(vec3 pos) {
    // Initialize the MaterialData for the entire scene, starting
    // with a SDF for the first object as the dist value
    MaterialData result = MaterialData(
        GROUND,
        sdfPlane(pos - vec3(0.0, -2.0, 0.0))
    );

    float distanceToObject;

    // Check which scene object the current point is closest to, and the color it accordingly
    // If the we are closer to this object than we are to the current distance to any object, 
    // then we should reassign the MaterialData's color attribute.

    // Box One
    distanceToObject = sdfBox(
        (pos - vec3(- 4.0, remap(cos(uTime), -1.0, 1.0, 0.0, 1.25), 5.0)) * rotateX(uTime * 0.5), 
        vec3(1.0)
    );
    result.color = distanceToObject < result.dist ? GRAY : result.color;
    result.dist = min(result.dist, distanceToObject);

    // Box Two
    distanceToObject = sdfBox(
        (pos - vec3(4.0, remap(sin(uTime), -1.0, 1.0, 0.0, 2.0), 5.0)) * rotateY(- uTime * 0.5), 
        vec3(1.0)
    );
    result.color = distanceToObject < result.dist ? GRAY : result.color;
    result.dist = min(result.dist, distanceToObject);

    // Sphere
    distanceToObject = sdfSphere(pos - vec3(0.0, 0.5, 5.0), 1.5);
    result.color = distanceToObject < result.dist ? GRAY : result.color;
    result.dist = min(result.dist, distanceToObject);

    return result;
}

vec3 CalculateNormal(vec3 pos) {
    // EPS is the epsilon (margin) for the samples
    const float EPS = 0.001;

    vec3 samples = vec3(
        // Sample on X axis
        map(pos + vec3(EPS, 0.0, 0.0)).dist - map(pos - vec3(EPS, 0.0, 0.0)).dist,
        // Sample on Y axis
        map(pos + vec3(0.0, EPS, 0.0)).dist - map(pos - vec3(0.0, EPS, 0.0)).dist,
        // Sample on Z axis
        map(pos + vec3(0.0, 0.0, EPS)).dist - map(pos - vec3(0.0, 0.0, EPS)).dist
    );
    return normalize(samples);
}

const float mint    = 0.01;
const float maxt    = 3.00;
const float w       = 0.10;

float CalculateShadow(vec3 pos, vec3 lightDirection) {
    float res = 1.0;
    float ph = 1e10;

    float t = mint;

    for (int i = 0; i < 32; ++i) {
        float distanceToScene = map(pos + lightDirection * t).dist;

        float y = (i == 0) ? 0.0 : distanceToScene * distanceToScene / (2.0 * ph);

        // float y = distanceToScene * distanceToScene / (2.0 * ph);
        float d = sqrt(distanceToScene * distanceToScene - y * y);
        res = min(res, d / (w * max(0.0, t - y)));
        ph = distanceToScene;
        t += distanceToScene;

        if (res < 0.0001 || t > maxt) break;
    }

    res = clamp(res, 0.0, 1.0);
    return res*res*(3.0 - 2.0 * res);
}

vec3 CalculateLightning(vec3 pos, vec3 normal, vec3 rayOrigin) {
    // Check how similar the normal for the point is to the light direction
    // Are they facing in a similar direction?
    // float dotProduct = dot(normal, lightDirection);
    // dotProduct = saturate(dotProduct);

    vec3 lighting;

    // Ambient
    vec3 ambient = vec3(0.5);

    // Hemi Lighting
    float hemiMix = remap(normal.y, -1.0, 1.0, 0.0, 1.0);
    vec3 hemi = mix(GROUND, SKY, hemiMix);

    // Diffuse Lighting (Lambertion Lighting)
    // Figure out the direction of the light source to this pixel
    // Sun, light bulbs, etc.
    // vec3 spot = lightColor * dotProduct;
    vec3 diffusePosition = vec3(1.0, 2.0, -1.0);
    vec3 diffuseDirection = normalize(diffusePosition);
    vec3 diffuseColor = vec3(1.0, 1.0, 1.0);

    // You can do a max function, a clamp function , or a saturate function here,
    // the point is we only want positive values between 0.0 and 1.0.
    float diffuseDotProduct = clamp(dot(diffuseDirection, normal), 0.0, 1.0);
    vec3 diffuse = diffuseDotProduct * diffuseColor;

    // Phong Specular

    vec3 viewDirection = normalize(rayOrigin - pos);
    vec3 reflectionVector = normalize(reflect(-diffuseDirection, normal));
    float phongValue = max(0.0, dot(viewDirection, reflectionVector));
    phongValue = pow(phongValue, 32.0);

    vec3 specular = vec3(phongValue);

    lighting =  (ambient * 0.0) +
                // Hemi Light
                (hemi * 1.0) +
                // Spot Light
                (diffuse * 1.0) +
                specular;

                
    float shadow = CalculateShadow(pos, diffuseDirection);
    lighting *= shadow;

    return lighting;
}

// Determine the max number of steps the ray marching algorithm can takes
const int NUM_STEPS = 256;
const float MAX_DIST = 1000.0;

vec3 RayMarch(vec3 rayOrigin, vec3 rayDirection) {

    vec3 pos;
    MaterialData material = MaterialData(vec3(0.0), 0.0);

    for (int i = 0; i < NUM_STEPS; ++i) {
        pos = rayOrigin + material.dist * rayDirection;

        MaterialData result = map(pos);

        // Case 1: distToScene is negative, we are intersecting with the scene
        if (result.dist < 0.001) {
            break;
        }

        // If we don't hit here, then we can safely add distToScene to the dist value
        material.dist += result.dist;
        material.color = result.color;

        // Case 2: Now, maybe at this point we are outside of the bounds of the scene,
        // which we define as MAX_DIST
        if (material.dist > MAX_DIST) {
            return SKY;
        }

        // Case 3: Loop around to the next step
    }

    // Finished loop

    // Lighting
    // vec3 lightDirection = normalize(vec3(1.25, 2.0, -1.0));
    // vec3 lightColor = WHITE;
    vec3 normal = CalculateNormal(pos);

    vec3 lighting = CalculateLightning(pos, normal, rayOrigin);

    return material.color * lighting;
}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;

    vec3 rayOrigin = vec3(0.0, 0.0, 0.0);
    vec3 rayDirection = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));

    vec3 color = RayMarch(rayOrigin, rayDirection);

    gl_FragColor = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}