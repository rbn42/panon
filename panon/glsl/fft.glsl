#version 430
// based on the algorithm described in http://research.microsoft.com/pubs/70576/tr-2008-62.pdf
#define SIZE 1024
#define SIZE2 4
#define PI 3.14159265358979323844
layout(local_size_x = SIZE) in;
layout(std430) buffer;
//layout(binding = 0, r32f) writeonly uniform image2D dest_texture;
layout(binding = 1) readonly buffer Input {
    float input_data[SIZE*SIZE2];
};
layout (std430, binding = 2) writeonly buffer Output {
    float v2[SIZE*SIZE2];
};


uniform uint real_size;

shared float values1[SIZE*SIZE2];
shared float values2[SIZE*SIZE2];
void synchronize()
{
    memoryBarrierShared();
    barrier();
}
vec2 getvalue(uint index) {
    float x=values1[index];
    float y=values2[index];
    return vec2(x,y);
}

void setvalue(uint index,vec2 value) {
    values1[index]=value.x;
    values2[index]=value.y;
}

void
fft_pass(int ns, int source,uint i)
{
    uint base = (i/ns)*(ns/2);
    uint offs = i%(ns/2);

    uint i0 = base + offs;
    uint i1 = i0 + real_size/2;

    vec2 v0 = getvalue(i0*2+source);
    vec2 v1 = getvalue(i1*2+source);

    float a = -2.*PI*float(i)/ns;

    float t_re = cos(a);
    float t_im = sin(a);

    setvalue(i*2+source ^ 1, v0 + vec2(dot(vec2(t_re, -t_im), v1), dot(vec2(t_im, t_re), v1)));
}

void main()
{
    uint i = gl_LocalInvocationID.x*SIZE2;
    for(uint i2=0; i2<SIZE2; i2++) {
        uint index=i+i2;
        if(index>=real_size)
            break;
        setvalue(index*2+0,  vec2(input_data[index], 0.));
    }
    synchronize();

    int source = 0;

    for (int n = 2; n <= SIZE; n *= 2) {
        for(uint i2=0; i2<SIZE2; i2++) {
            uint index=i+i2;
            if(index>=real_size)
                break;
            fft_pass(n, source,index);
        }
        source ^= 1;
        synchronize();
    }

    for(uint i2=0; i2<SIZE2; i2++) {
        uint index=i+i2;
        if(index>=real_size)
            break;
        v2[index]=length(getvalue(index*2+source));
    }
}
