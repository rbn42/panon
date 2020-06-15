#version 130

out vec4 out_Color;
in mediump vec2 qt_TexCoord0;

uniform sampler2D newWave; 
uniform sampler2D waveBuffer; 

uniform int     bufferSize;
uniform int     newWaveSize;

void main() {
    float x=qt_TexCoord0.x*bufferSize;
    float y=qt_TexCoord0.y*2;
    
    if(y<2){
        if(x>= bufferSize-newWaveSize ){
            out_Color=texelFetch(newWave,ivec2(x-bufferSize+newWaveSize,y),0);
        }else{
            out_Color=texelFetch(waveBuffer,ivec2(x+newWaveSize,y),0);
        }
    }
}
