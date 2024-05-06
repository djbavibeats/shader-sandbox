/**
 * Varyings
 */
varying vec2 vUvs;

/**
 * Uniforms
 */
uniform float uTime;
uniform vec2 uResolution;
uniform sampler2D uDiffuse1;
uniform sampler2D uDiffuse2;
uniform sampler2D uVignette;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

void main() {
    vec2 coords = fract(vUvs * vec2(1.0, 1.0));
    vec3 color = texture2D(uDiffuse2, coords).xyz;
        
    vec2 pushedCoords = coords;

    float pausePoint = 0.25;
    float resumePoint = 0.75;
    float stretchDist = resumePoint - pausePoint;

    float distToCenter = length(coords - 0.5);
    float d = sin(distToCenter * 32.0 - uTime * 0.5);
    vec2 dir = normalize(pushedCoords - 0.5);
    vec2 rippleCoords = pushedCoords + d * dir;

    float time = abs(sin(uTime * 0.125));
    color = texture2D(uDiffuse1, pushedCoords).xyz;
    if (time > pausePoint && time < resumePoint) {
        if (pushedCoords.y > pausePoint && pushedCoords.y < time) {
            pushedCoords.y = pausePoint;
            if (
                length(coords - vec2(0.5, 0.5)) < (stretchDist / 2.0 - 0.05)
            ) {
                // pushedCoords = pushedCoords;
                color = texture2D(uDiffuse1, rippleCoords).xyz;
            } else {
                color = texture2D(uDiffuse1, pushedCoords).xyz;
            }
        } else if (pushedCoords.y > time) {
            pushedCoords.y = pushedCoords.y - time + pausePoint; 
            color = texture2D(uDiffuse1, pushedCoords).xyz;
        }
        
    } 
    if (time > resumePoint) {
        float timemap = remap(time, resumePoint, 1.0, 0.0, stretchDist);
        float timemap2 = remap(time, resumePoint, 1.0, pausePoint, resumePoint);

        if (pushedCoords.y > resumePoint) {
            pushedCoords.y = pushedCoords.y - stretchDist;
            color = texture2D(uDiffuse1, pushedCoords).xyz;
        } else if (pushedCoords.y > timemap2) {
            pushedCoords.y = pausePoint;
            if (
                length(coords - vec2(0.5, 0.5)) < (stretchDist / 2.0 - 0.05)
            ) {
                pushedCoords = pushedCoords;
                color = texture2D(uDiffuse1, rippleCoords).xyz;
            } else {
                color = texture2D(uDiffuse1, pushedCoords).xyz;
            }
        } else {
            pushedCoords.y = pushedCoords.y - timemap;
            color = texture2D(uDiffuse1, pushedCoords).xyz;
        }
    }
    
    // color = texture2D(uDiffuse1, pushedCoords).xyz;
    gl_FragColor = vec4(color, 1.0);
}