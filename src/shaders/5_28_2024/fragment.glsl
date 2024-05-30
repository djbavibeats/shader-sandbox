varying vec2 vUvs;

uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uTime;
uniform sampler2D uDiffuse1;

#define PI 3.14159265359

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

float plot(vec2 coords, float shape) {
  return smoothstep(0.01, 0.00, abs(coords.y - shape));
}

vec3 DrawBackground(float sequence_length, float sequence_time) {
  float shape = pow(abs(vUvs.x - 0.75), 2.5) - 0.25;

  vec3 coords = vec3(
    vUvs.x * 15.0 + uTime * 0.25, 
    vUvs.y * 15.0, 
    uTime * 0.5
  );
  float noisePattern = 0.0;
  noisePattern = remap(fbm(vec3(coords), 4, 0.5, 2.0), -1.0, 1.0, 0.0, 1.0);
  // float noisePattern = fbm(vec3((vUvs - 0.5) * uResolution * fract(uTime * 1.0), 0.0) * 0.0125, 64, 0.5, 2.0);

  // Sunrise
  vec3 morning_green = vec3(0.27843, 0.93725, 0.65882);
  vec3 morning_pink = vec3(0.64705, 0.08627, 0.58431);
  vec3 morning = mix(morning_green, morning_pink, 
    smoothstep(0.0, 1.0, vUvs.y - shape)
    // noisePattern
  ) * noisePattern;

  // Sunset
  vec3 evening_orange = vec3(0.97647, 0.56470, 0.34117);
  vec3 evening_blue = vec3(0.33725, 0.34509, 0.57647);
  vec3 evening = mix(evening_orange, morning_green, 
    smoothstep(0.0, 1.0, vUvs.y - shape)
    // noisePattern
  ) * noisePattern;

  vec3 color;
  

  if (sequence_time < sequence_length * 0.5) {
    color = mix(morning, evening, smoothstep(0.0, sequence_length * 0.5, sequence_time));
  } else {
    color = mix(evening, morning, smoothstep(sequence_length * 0.5, sequence_length * 1.0, sequence_time));
  }

  return color;
}

float sdfCircle(vec2 pos, float rad) {
  return length(pos) - rad;
}
float random (vec2 pos) {
    return fract(sin(dot(pos.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 pos) {
  return pos.x;
}

void main() {
    vec2 coords = vUvs;
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;
    vec2 mouseCoords = uMouse * (uResolution / 2.0);
    vec3 color;
    vec3 sample1 = texture2D(uDiffuse1, coords).xyz;

    float shape = pow(coords.y, 0.4);

    float SEQUENCE_LENGTH = 10.0;
    float SEQUENCE_TIME  = mod(uTime, SEQUENCE_LENGTH);
    // SEQUENCE_TIME = 8.0;

    color = DrawBackground(SEQUENCE_LENGTH, SEQUENCE_TIME);

    float noiseSample = fbm(vec3(pixelCoords, 0.0) * 0.005, 4, 0.5, 2.0);
    float circle = sdfCircle(
      (pixelCoords - mouseCoords) * noiseSample, 
      remap(sin(uTime * 2.0), -1.0, 1.0, 0.90, 1.10) * 25.0
    );

    // Shadow
    vec3 shadowColor = vec3(0.64705, 0.08627, 0.58431);
    float shadowAmount = smoothstep(0.0, 50.0, circle);
    shadowAmount = pow(shadowAmount, remap(sin(uTime * 1.0), -1.0, 1.0, 0.25, 0.45));

    color = mix(shadowColor, color, shadowAmount);

    // Glow
    vec3 glowColor = vec3(0.64705, 0.08627, 0.58431);
    float glowAmount = smoothstep(0.0, 8.0, abs(circle - 25.0));
    glowAmount = 1.0 - pow(glowAmount, 0.05);
    color += glowAmount * glowColor;
    
    // Base Shape
    color = mix(sample1, color, smoothstep(0.0, 25.0, circle));
    
    gl_FragColor = vec4(color, 1.0);
}