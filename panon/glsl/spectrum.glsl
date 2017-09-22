#version 430
// based on the algorithm described in http://research.microsoft.com/pubs/70576/tr-2008-62.pdf
#define SIZE 1024
#define SIZE2 16
#define PI 3.14159265358979323844
layout(local_size_x = SIZE) in;
layout(std430, binding = 1) readonly buffer Input {
    float input_data[SIZE*SIZE2];
};
layout (std430, binding = 2) writeonly buffer Output {
    float output_data[SIZE];
};

uniform uint rel;
uniform uint history_index;

shared vec2 values[SIZE][2];

void synchronize(){
    memoryBarrierShared();
    barrier();
}
void fft_pass(int ns, int source, uint i) {
    uint base = (i/ns)*(ns/2);
    uint offs = i%(ns/2);
    uint i0 = base + offs;
    uint i1 = SIZE/2+i0 ;//#-1-i0;
    vec2 v0 = values[i0][source];
    vec2 v1 = values[i1][source];
    float a = -2.*PI*float(i)/ns;
    float t_re = cos(a);
    float t_im = sin(a);
    values[i][source ^ 1] = v0 + vec2(dot(vec2(t_re, -t_im), v1), dot(vec2(t_im, t_re), v1));
}
void main() {
    uint i = gl_LocalInvocationID.x;
    values[i][0] = vec2(0, 0.);

    uint from=history_index-SIZE*rel;
    uint i2=from+i*rel;
    i2%=SIZE*SIZE2;
    values[i][0].x+=input_data[i2];
    synchronize();
    int source = 0;
    for (int n = 2; n <= SIZE; n *= 2) {
        fft_pass(n, source,i);
        source ^= 1;
        synchronize();
    }
    output_data[i] = length(values[i][source]);
}
