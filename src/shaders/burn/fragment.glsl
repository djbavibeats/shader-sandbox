varying vec2 vUvs;

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uDiffuse1;
uniform sampler2D uDiffuse2;

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}

vec3 hash(vec3 p) {
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
            dot(p,vec3(269.5,183.3,246.1)),
            dot(p,vec3(113.5,271.9,124.6)));
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(in vec3 p) {
  vec3 i = floor( p );
  vec3 f = fract( p );
	vec3 u = f*f*(3.0-2.0*f);

  return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                        dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                   mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                        dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
              mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                        dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                   mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                        dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float fbm(vec3 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 1.0;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;
  total = smoothstep(-1.0, 1.0, total);

  return total;
}

float sdfCircle(vec2 p, float r) {
  return length(p) - r;
}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;

    float noiseSample = fbm(vec3(pixelCoords, 0.0) * 0.005, 4, 0.5, 2.0);
    float size = smoothstep(0.00, 15.00, uTime) * (50.0 + length(uResolution)) * 0.5;
    float d = sdfCircle(pixelCoords + 50.0 * noiseSample, size);

    vec2 distortion = noiseSample / uResolution;
    vec2 uvDistortion = distortion * 20.0 * smoothstep(80.0, 20.0, d);

    vec3 sample1 = texture2D(uDiffuse1, vUvs + uvDistortion).xyz;
    vec3 sample2 = texture2D(uDiffuse2, vUvs).xyz;
    vec3 color = sample1;

    // Create the dark burning effect
    float burnAmount = 1.0 - exp(-d*d*0.001);
    color = mix(vec3(0.0), color, burnAmount);

    vec3 FIRE_COLOR = vec3(1.00, 0.50, 0.20);
    float orangeAmount = smoothstep(0.00, 10.00, d);
    orangeAmount = pow(orangeAmount, 0.25);
    color = mix(FIRE_COLOR, color, orangeAmount);

    color = mix(sample2, color, smoothstep(0.0, 1.0, d));

    // Add a fiery glow
    float glowAmount = smoothstep(0.0, 32.0, abs(d));
    glowAmount = 1.0 - pow(glowAmount, 0.125);
    color += glowAmount * vec3(1.0, 0.2, 0.05);

    gl_FragColor = vec4(color, 1.0);
}