/**
 * Varyings
 */
varying vec2 vUvs;

/**
 * Uniforms
 */
uniform float uTime;
uniform vec2 uResolution;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

// Copyright (C) 2011 by Ashima Arts (Simplex noise)
// Copyright (C) 2011-2016 by Stefan Gustavson (Classic noise and others)
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://github.com/ashima/webgl-noise/tree/master/src
vec3 mod289(vec3 x)
{
    return x - floor(x / 289.0) * 289.0;
}

vec4 mod289(vec4 x)
{
    return x - floor(x / 289.0) * 289.0;
}

vec4 permute(vec4 x)
{
    return mod289((x * 34.0 + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - r * 0.85373472095314;
}

vec4 snoise(vec3 v)
{
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);

    // First corner
    vec3 i  = floor(v + dot(v, vec3(C.y)));
    vec3 x0 = v   - i + dot(i, vec3(C.x));

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.x;
    vec3 x2 = x0 - i2 + C.y;
    vec3 x3 = x0 - 0.5;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec4 p =
      permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0))
                            + i.y + vec4(0.0, i1.y, i2.y, 1.0))
                            + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    vec4 j = p - 49.0 * floor(p / 49.0);  // mod(p,7*7)

    vec4 x_ = floor(j / 7.0);
    vec4 y_ = floor(j - 7.0 * x_); 

    vec4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
    vec4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 g0 = vec3(a0.xy, h.x);
    vec3 g1 = vec3(a0.zw, h.y);
    vec3 g2 = vec3(a1.xy, h.z);
    vec3 g3 = vec3(a1.zw, h.w);

    // Normalize gradients
    vec4 norm = taylorInvSqrt(vec4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
    g0 *= norm.x;
    g1 *= norm.y;
    g2 *= norm.z;
    g3 *= norm.w;

    // Compute noise and gradient at P
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    vec4 m2 = m * m;
    vec4 m3 = m2 * m;
    vec4 m4 = m2 * m2;
    vec3 grad =
      -6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 +
      -6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 +
      -6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2 +
      -6.0 * m3.w * x3 * dot(x3, g3) + m4.w * g3;
    vec4 px = vec4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
    return 42.0 * vec4(grad, dot(m4, px));
}

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
//
// https://www.shadertoy.com/view/Xsl3Dl
vec3 hash3( vec3 p ) // replace this by something better
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
            dot(p,vec3(269.5,183.3,246.1)),
            dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec3 p )
{
  vec3 i = floor( p );
  vec3 f = fract( p );
	
	vec3 u = f*f*(3.0-2.0*f);

  return mix( mix( mix( dot( hash3( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                        dot( hash3( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                   mix( dot( hash3( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                        dot( hash3( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
              mix( mix( dot( hash3( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                        dot( hash3( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                   mix( dot( hash3( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                        dot( hash3( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float fbm(vec3 p, int octaves, float persistence, float lacunarity, float exponentiation) {
  float amplitude = 0.5;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = snoise(p * frequency).w;
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;
  total = total * 0.5 + 0.5;
  total = pow(total, exponentiation);

  return total;
}

vec3 GenerateGridStars(vec2 pixelCoords, float starRadius, float cellWidth, float seed, bool twinkle) {
    vec2 cellCoords = (fract(pixelCoords / cellWidth) - 0.5) * cellWidth;
    vec2 cellID = floor(pixelCoords / cellWidth) + seed / 100.0;
    vec3 cellHashValue = hash3(vec3(cellID, 0.0));

    float starBrightness = saturate(cellHashValue.z);
    vec2 starPosition = vec2(0.0);
    starPosition += cellHashValue.xy * (cellWidth * 0.5 - starRadius * 4.0);
    float distToStar = length(cellCoords - starPosition);
    // float glow = smoothstep(starRadius + 1.0, starRadius, distToStar);
    float glow = exp(- 2.0 * distToStar / starRadius);

    if (twinkle) {
        float noiseSample = noise(vec3(cellID, uTime * 1.5));
        float twinkleSize = (
            remap(noiseSample, -1.0, 1.0, 1.0, 0.1) * starRadius * 6.0);
        vec2 absDist = abs(cellCoords - starPosition);
        float twinkleValue = smoothstep(starRadius * 0.25, 0.0, absDist.y) *
            smoothstep(twinkleSize, 0.0, absDist.x);
        twinkleValue += smoothstep(starRadius * 0.25, 0.0, absDist.x) *
            smoothstep(twinkleSize, 0.0, absDist.y);
        glow += twinkleValue;
    }
 
    return vec3(glow * starBrightness);

}

vec3 GenerateStars(vec2 pixelCoords) {
    vec3 stars = vec3(0.0);
    
    float size = 4.0;
    float cellWidth = 500.0;
    for (float i = 0.0; i <= 2.0; i++) {
        stars += GenerateGridStars(pixelCoords, size, cellWidth, i, true);
        size *= 0.5;
        cellWidth *= 0.35;
    }

    for (float i = 3.0; i < 5.0; i++) {
        stars += GenerateGridStars(pixelCoords, size, cellWidth, i, false);
        size *= 0.5;
        cellWidth *= 0.35;
    }
    return stars;
}   

float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

float map(vec3 pos) {
    return fbm(pos, 6, 0.5, 2.0, 4.0);
}

vec3 calcNormal(vec3 pos, vec3 n) {
    vec2 e = vec2(0.0001, 0.0);
    return normalize(
        n + -500.0 * vec3(
            map(pos + e.xyy) - map(pos - e.xyy),
            map(pos + e.yxy) - map(pos - e.yxy),
            map(pos + e.yyx) - map(pos - e.yyx)
        )
    );
}

mat3 rotateY(float radians) {
    float s = sin(radians);
    float c = cos(radians);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

float earth = 350.0;

vec3 DrawPlanet(vec2 pixelCoords, vec3 color) {
    float d = sdfCircle(pixelCoords, earth);

    vec3 planetColor = vec3(1.0);
    if (d <= 0.0) {
        float x = pixelCoords.x / earth;
        float y = pixelCoords.y / earth;
        float z = sqrt(1.0 - x * x - y * y);
        mat3 planetRotation = rotateY(uTime * 0.1);
        vec3 viewNormal = vec3(x, y, z);
        vec3 wsPosition = planetRotation * viewNormal;
        vec3 wsNormal = planetRotation * normalize(wsPosition);
        vec3 wsViewDir = planetRotation * vec3(0.0, 0.0, 1.0);

        vec3 noiseCoord = wsPosition * 2.0;
        float noiseSample = fbm(noiseCoord, 6, 0.5, 2.0, 4.0);
        float moistureMap = fbm(
            noiseCoord * 0.5 + vec3(20.0), 2, 0.5, 2.0, 1.0);

        // Coloring
    vec3 waterColor = mix(
        vec3(0.01, 0.09, 0.55),
        vec3(0.09, 0.26, 0.57),
        smoothstep(0.02, 0.06, noiseSample));
    vec3 landColor = mix(
        vec3(0.5, 1.0, 0.3),
        vec3(0.0, 0.7, 0.0),
        smoothstep(0.05, 0.1, noiseSample));
    landColor = mix(
        vec3(1.0, 1.0, 0.5),
        landColor,
        smoothstep(0.4, 0.5, moistureMap));
    landColor = mix(
        landColor, vec3(0.5), smoothstep(0.1, 0.2, noiseSample));
    landColor = mix(
        landColor, vec3(1.0), smoothstep(0.2, 0.3, noiseSample));
    landColor = mix(
        landColor, vec3(0.9), smoothstep(0.6, 0.9, abs(viewNormal.y)));

    planetColor = mix(
        waterColor, landColor, smoothstep(0.05, 0.06, noiseSample));

        // Lighting
    vec2 specParams = mix(
        vec2(0.5, 32.0),
        vec2(0.01, 2.0),
        smoothstep(0.05, 0.06, noiseSample));
    vec3 wsLightDir = planetRotation * normalize(vec3(0.5, 1.0, 0.5));
    vec3 wsSurfaceNormal = calcNormal(noiseCoord, wsNormal);

    float wrap = 0.05;
    float dp = max(
        0.0, (dot(wsLightDir, wsSurfaceNormal) + wrap) / (1.0 + wrap));

    vec3 lightColor = mix(
        vec3(0.25, 0.0, 0.0),
        vec3(0.75),
        smoothstep(0.05, 0.5, dp));
    vec3 ambient = vec3(0.002);
    vec3 diffuse = lightColor * dp;

    vec3 r = normalize(reflect(-wsLightDir, wsSurfaceNormal));
    float phongValue = max(0.0, dot(wsViewDir, r));
    phongValue = pow(phongValue, specParams.y);

    vec3 specular = vec3(phongValue) * specParams.x * diffuse;

    vec3 planetShading = planetColor * (diffuse + ambient) + specular;
    planetColor = planetShading;

    // Fresnel
    float fresnel = smoothstep(1.0, 0.1, viewNormal.z);
    fresnel = pow(fresnel, 8.0) * dp;
    planetColor = mix(planetColor, vec3(0.0, 0.5, 1.0), fresnel);
    }

    color = mix(color, planetColor, smoothstep(0.0, -1.0, d));

    if (d < (earth / 10.0) && d >= -1.0) {
        float x = pixelCoords.x / (earth + (earth / 10.0));
        float y = pixelCoords.y / (earth + (earth / 10.0));
        float z = sqrt(1.0 - x * x - y * y);
        vec3 normal = vec3(x, y, z);

        float lighting = dot(normal, normalize(vec3(0.5, 1.0, 0.5)));
        lighting = smoothstep(-0.15, 1.0, lighting);

        vec3 glowColor = vec3(0.05, 0.3, 0.9) *
            exp(- 0.01 * d * d) * lighting * 0.75;
        color += glowColor;
    }

    return vec3(color);
}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;

    vec3 color = vec3(0.0);
    color = GenerateStars(pixelCoords);
    color = DrawPlanet(pixelCoords, color);
    
    gl_FragColor = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}