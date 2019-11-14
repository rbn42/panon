#version 130
// Adapted from https://www.shadertoy.com/view/Ml2GWy. Looks better with range from 0 to 1,800Hz
// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pos = fragCoord.xy/4+ iTime;

    vec3 col = vec3(0.0);
    for( int i=0; i<4; i++ ) 
    {
        vec2 a = floor(pos);
        vec2 b = fract(pos);

        
        vec4 w = fract((sin(a.x*7.0+31.0*a.y + 0.01*iTime)+vec4(0.035,0.01,0.0,0.7))*13.545317); // randoms

        if(i>2){
            vec4 sample1    = texture(iChannel2, vec2((a.x*pow(2,i) -iTime)*4/iResolution.x,0)) ;
            vec4 sample2    = texture(iChannel2, vec2(((a.x+0.5)*pow(2,i)-iTime) *4/iResolution.x,0)) ;
            w.w=w.w>.5?sample1.r:sample2.r;
            w.w*=1.6;
        }
                
        col += w.xyz *                                   // color
               smoothstep(0.45,0.55,w.w) *               // intensity
               sqrt( 16.0*b.x*b.y*(1.0-b.x)*(1.0-b.y) ); // pattern
        
        pos /= 2.0; // lacunarity
        col /= 2.0; // attenuate high frequencies
    }
    
    col = pow( 2.5*col, vec3(1.0,1.0,0.7) );    // contrast and color shape
    
    fragColor = vec4( col, 1.0 );
}
