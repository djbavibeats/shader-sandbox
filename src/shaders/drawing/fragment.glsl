/**
 * Varyings
 */
varying vec2 vUvs;

/**
 * Uniforms
 */
uniform float uTime;
uniform vec2 uResolution;


/**
 * Colors
 */
vec3 white = vec3(1.0);
vec3 black = vec3(0.0);
vec3 darkgrey = vec3(0.15, 0.15, 0.135);

mat2 rotate2D( float angle ) {
    mat2 t = mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    );
    return t;
}

float hash(vec2 v) {
    float t = dot(v, vec2(36.5323, 73.945));
    return sin(t);
}

float dot2(in vec2 v ) { return dot(v,v); }
float sdfTrapezoid( vec2 p, float r1, float r2, float he ) {
    vec2 k1 = vec2(r2,he);
    vec2 k2 = vec2(r2-r1,2.0*he);
    p.x = abs(p.x);
    vec2 ca = vec2(p.x-min(p.x,(p.y<0.0)?r1:r2), abs(p.y)-he);
    vec2 cb = p - k1 + k2*clamp( dot(k1-p,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

void main() {
    vec2 pixelCoords = (vUvs - 0.5) * uResolution;
    vec3 color = darkgrey;

    const float NUM_BOXES = 24.0;
    const float BOX_FACTOR = 24.0;
    float time = uTime * 0.75;
    for (float i = 0.0; i < NUM_BOXES; i += 1.0) {
        vec2 boxPos = pixelCoords;
        float r = hash(vec2(i * 13.0)) * 1.5 + 2.5; 
        
        boxPos = rotate2D(3.14159 *(i / (NUM_BOXES * 0.5))) * boxPos; 
        boxPos = rotate2D(3.14159 - time * 0.125) * boxPos;
        boxPos.x += BOX_FACTOR * (BOX_FACTOR / 4.0) + (sin(time * r * 0.5) * BOX_FACTOR);
        boxPos = rotate2D(3.14159 * 0.5) * boxPos;

        vec2 shadowOffset = vec2(3.0, 4.0);
        float boxShadow = sdfTrapezoid( boxPos + shadowOffset, 5.0, 14.0, BOX_FACTOR) - 1.5;
        color = mix(vec3(0.0, 0.0, 0.0), color, smoothstep(-12.0, 12.0, boxShadow));

        float box = sdfTrapezoid( boxPos, 5.0, 14.0, BOX_FACTOR) - 1.5;
        color = mix(vec3(abs(cos(vUvs.x + time * 0.25)), 0.0, abs(sin(vUvs.y + time * 0.25))), color, smoothstep(0.0, 1.0, box));

        float boxGlow = sdfTrapezoid( boxPos, 5.0, 14.0, BOX_FACTOR) - 1.5;
        color += 5.0 * mix(vec3(vUvs.x, 0.0, vUvs.y), vec3(0.0, 0.0, 0.0), smoothstep(-4.0 - abs(sin(time * 2.0) * 2.0), 4.0 + abs(sin(time * 2.0) * 2.0), boxGlow));


    }

    gl_FragColor = vec4(color, 1.0);
}