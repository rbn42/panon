#version 130
/*
 * This shader is copied from https://www.shadertoy.com/view/lldyDs, created by
 * eclmist (https://www.shadertoy.com/user/eclmist), licensed under a Creative 
 * Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 */
float distLine(vec2 p, vec2 a, vec2 b) {
	vec2 ap = p - a;
    vec2 ab = b - a;
    float aDotB = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    return length(ap - ab * aDotB);
}

float drawLine(vec2 uv, vec2 a, vec2 b) {
    float line = smoothstep(0.014, 0.01, distLine(uv, a, b));
    float dist = length(b-a);
    return line * (smoothstep(1.3, 0.8, dist) * 0.5 + smoothstep(0.04, 0.03, abs(dist - 0.75)));
}

float n21(vec2 i) {
    i += fract(i * vec2(223.64, 823.12));
    i += dot(i, i + 23.14);
    return fract(i.x * i.y);
}

vec2 n22(vec2 i) {
    float x = n21(i);
    return vec2(x, n21(i+x));
}

vec2 getPoint (vec2 id, vec2 offset) {
	return offset + sin(n22(id + offset) * iTime * 1.0) * 0.4;
}

float layer (vec2 uv) {
    float m = 0.0;
    float t = iTime * 2.0;
   
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv) - 0.5;
    
    vec2 p[9];
    int i = 0;
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
        	p[i++] = getPoint(id, vec2(x,y));
        }
    }
    
    for (int i = 0; i < 9; i++) {
    	m += drawLine(gv, p[4], p[i]);
        float sparkle = 1.0 / pow(length(gv - p[i]), 1.5) * 0.005;
        m += sparkle * (sin(t + fract(p[i].x) * 12.23) * 0.4 + 0.6);
    }
    
    m += drawLine(gv, p[1], p[3]);
    m += drawLine(gv, p[1], p[5]);
    m += drawLine(gv, p[7], p[3]);
    m += drawLine(gv, p[7], p[5]);
     
    return m;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 c = sin(iTime * 2.0 * vec3(.234, .324,.768)) * 0.4 + 0.6;
    vec3 col = vec3(0);
    float fft = texelFetch(iChannel0, ivec2(76.0, 0.), 0).x / 2.0 + 0.5;
    c.x += (uv.x + 0.5);
    col += pow(-uv.y + 0.5, 5.0) * fft * c;
    
    float m = 0.0;
    float x = sin(iTime * 0.1);
    float y = cos(iTime * 0.2);
    
    mat2 rotMat = mat2(x, y, -y, x);
    uv *= rotMat;
    
    for (float i = 0.0; i <= 1.0; i+= 1.0/4.0) {
        float z = fract(i + iTime * 0.05);
        float size = mix(15.0, .1, z) * 1.50;
        float fade = smoothstep(0.0, 1.0,  z) * smoothstep(1.0, 0.9, z);
        m += layer((size * uv) + i * 10.0 ) * fade;
    }
    
    col += m * c;
    // Debug
    fragColor = vec4(col,1.0);
}
