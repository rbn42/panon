#version 130
/*
 * This shader is adapted from https://www.shadertoy.com/view/lldyDs, created by
 * eclmist (https://www.shadertoy.com/user/eclmist), licensed under a Creative 
 * Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 */

#define strength $strength 
#define near $near 
#define rear $rear 
#define max_life_time $max_life_time
#define opacity $opacity 

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
	return offset + sin(n22(id + offset) * iTime * 1.0) * 0.4+0.5;
}

vec3 layer (vec2 uv,int index_layer, int num_unit) {
    float m = 0.0;
    float t = iTime * 2.0;
   

    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv) - 0.5;
    
    vec2 p[9];
    int i = 0;
    float p_d[9];
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
            vec4 sample1= texelFetch(iChannel2,ivec2(index_layer+1,1+ abs(uv.x+x)) , 0);
            p_d[i]=(uv.x+x)>0?sample1.r:sample1.g;
            p[i] = getPoint(id, vec2(x,y));
            i++;
        }
    }
    
    for (int i = 0; i < 9; i++) {
        if(p_d[i]<=0)continue;
        float sparkle = 1.0 / pow(length(gv - p[i]), 1.5) * 0.015;
        m += sparkle * (sin(t + fract(p[i].x) * 12.23) * 0.4 + 0.6) * min(1,strength*p_d[i]) ;
    }

    vec3 c=getRGB(uv.x/ num_unit /2 +.5); 
     
    return m*c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int num_layer=min( int(iResolution.x-1) ,max_life_time) ;
    int num_unit=int(iResolution.y);

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.x*10;
    
    float x = sin(iTime * 0.1/2);
    float y = cos(iTime * 0.2/2);
    
    mat2 rotMat = mat2(x, y, -y, x);

    vec3 m =vec3(0); // 0.0;
    for (float i = 0.0; i <= 1.0; i+= 1.0/num_layer) {
        float z = fract(i - iTime * 0.00);
        float size = mix(rear * num_unit, near*num_unit, z) ;
        float fade = smoothstep(1.0, 0.0,  z) * smoothstep(1.0, 0.9, z);
        m += layer((size * uv) + i * 0.0,int(i*num_layer) ,num_unit) * fade;
    }
    

    fragColor.rgb=m;
    fragColor.a=opacity+ max(max(fragColor.r,fragColor.g),fragColor.b);

}
