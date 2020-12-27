#version 130

out vec4 out_Color;
in mediump vec2 qt_TexCoord0;

uniform sampler2D waveBuffer; 

uniform int     dftSize;
uniform int     bufferSize;

#define PI 3.14159265359

struct Data{float r;float g;};

Data fun(float k){

    int N=bufferSize;
        float vrc=0.0,vrs=0.0,vgc=0.0,vgs=0.0;
        for(int m=0;m<N;m++){
            vec4 s0=texelFetch(waveBuffer,ivec2(m,0),0);
            vec4 s1=texelFetch(waveBuffer,ivec2(m,1),0);
            float sr=s0.r/256.0+s1.r;
            float sg=s0.g/256.0+s1.g;
            sr=sr<0.5?sr:sr-1;
            sg=sg<0.5?sg:sg-1;
            vrc+=sr*cos(-2.0*PI*m*k/N);
            vrs+=sr*sin(-2.0*PI*m*k/N);
            vgc+=sg*cos(-2.0*PI*m*k/N);
            vgs+=sg*sin(-2.0*PI*m*k/N);
        }
    return Data(length(vec2(vrc,vrs)),length(vec2(vgc,vgs)));
}

void main() {
    float x=qt_TexCoord0.x*dftSize;
    if(x<dftSize ){
        out_Color.a=1;
        Data data=fun(x);
        out_Color.r=data.r*0.05; ///fun(0);
        out_Color.g=data.g*0.05; ///fun(0);
    }
}
//l=np.dot(d[:,0],np.cos( np.outer( -2*np.pi*m/n,k)))
