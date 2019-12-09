#version 130
/*
 * This shader is adapted from https://www.shadertoy.com/view/lldyDs, created by
 * eclmist (https://www.shadertoy.com/user/eclmist), licensed under a Creative
 * Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 */

#define strength $strength
#define near $near_side
#define rear $rear_side
#define max_life_time $max_life_time
#define opacity $opacity
#define density $density
#define depth $depth

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
    return offset + sin(n22(id + offset) * iTime * 1.0) * 0.4+0.0;
}

float layer (vec2 uv,int index_layer, float fade) {
    float m = 0.0;
    float t = iTime * 2.0;

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv) - 0.5;

    for (float y = -2.0; y <= 2.0; y++) {
        for (float x = -1.0; x <= 0.0; x++) {
            vec4 sample1= texelFetch(iChannel2,ivec2(index_layer+1,1+ uv.x+x), 0);
            float p_d=sample1.r;
            if(p_d<=0)continue;

            vec2 p = getPoint(id, vec2(x,y));
            float sparkle = 1.0 / pow(length(gv - p), 1.5) * 0.015;
            m += sparkle * (sin(t + fract(p.x) * 12.23) * 0.4 + 0.6) * min(0.5,strength*p_d*fade) ;
        }
    }

    return m;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    int num_unit=int(iResolution.y);

    vec2 uv = fragCoord /iResolution.xy -vec2(0,0.5 );

    vec3 m =vec3(0);
    float end_layer=max_life_time/1.0/depth  ;
    for (float i = 0.0; i <= end_layer ; i+= 1.0/depth) {
        float fade = smoothstep(1.0, (1-1/end_layer  )  ,  i) * smoothstep(1.0, 0.9, i);
        float size_x = mix(rear, near, i) *num_unit ;
        float size_y = mix(rear, near, i) * density*iResolution.y;
        vec3 c=getRGB(size_x*uv.x/ num_unit );
        m +=c* layer((vec2(size_x,size_y) * uv) + i * 0.0,int(i*depth),fade)  ;
    }

    fragColor.rgb=m;
    fragColor.a=opacity+ max(max(fragColor.r,fragColor.g),fragColor.b);

}
