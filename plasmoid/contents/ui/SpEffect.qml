import Qt3D.Core 2.14
import Qt3D.Render 2.14
Effect {

    property alias imageShaderSource: imageShader.fragmentShaderCode
    property alias bufferShaderSource: bufferShader.fragmentShaderCode

    techniques: [
        Technique {

            filterKeys: [FilterKey { name: "tech"; value: "run" } ]

            renderPasses: [
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "gldftpass" } ]
                    shaderProgram: gldftShader
                },
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "remotedftpass" } ]
                    shaderProgram: remotedftShader
                },
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "bufferpass" } ]
                    shaderProgram: bufferShader
                },
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "flipbufferpass" } ]
                    shaderProgram: flipbufferShader
                },
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "imagepass" } ]
                    shaderProgram: imageShader
                },
                RenderPass {
                    filterKeys: [FilterKey { name: "pass"; value: "finalpass" } ]
                    shaderProgram: finalShader
                }
            ]
        }
    ]


    ShaderProgram {
        id: gldftShader
        computeShaderCode:"#version 430
            uniform int npwavelength;
            writeonly uniform image2D remotedftdOutput;
            layout (local_size_x = 512) in;
            struct WaveData
            {
                int l;
                int r;
            };
            layout (std430, binding = 0) coherent buffer Npwave
            {
                WaveData wavearray[];
            } data;

            #define PI 3.14159265359
            struct DFTData{double l;double r;};
            DFTData computeDFT(uint k){
                int N=npwavelength;
                double vrc=0.0,vrs=0.0,vgc=0.0,vgs=0.0;
                for(int m=0;m<N;m++){
                    int sr=data.wavearray[m].l;
                    int sg=data.wavearray[m].r;
                    vrc+=sr*cos(float(-2.0)*float(PI)*float(m)*float(k)/float(N));
                    vrs+=sr*sin(float(-2.0)*float(PI)*float(m)*float(k)/float(N));
                    vgc+=sg*cos(float(-2.0)*float(PI)*float(m)*float(k)/float(N));
                    vgs+=sg*sin(float(-2.0)*float(PI)*float(m)*float(k)/float(N));
                }
                return DFTData(length(vec2(vrc,vrs)),length(vec2(vgc,vgs)));
            }

            void main() {
                uint globalId = gl_GlobalInvocationID.x;
                if(globalId<512)
                    while(globalId<npwavelength){
                        DFTData dftdata=computeDFT(globalId);
                        ivec2 storePos = ivec2(globalId,0);
                        imageStore(remotedftdOutput, storePos, vec4(dftdata.l/22256.0,dftdata.r/22256.0,0 ,1));
                        //imageStore(remotedftdOutput, storePos, vec4(1,0.6,0 ,1));
                        globalId+=512;
                    }
            }"
    }

    ShaderProgram {
        id: remotedftShader
        computeShaderCode:"#version 430
            uniform int dftlength;
            writeonly uniform image2D remotedftdOutput;
            layout (local_size_x = 256) in;
            struct DFTData
            {
                int left;
                int right;
            };
            layout (std430, binding = 0) coherent buffer Npdft
            {
                DFTData dftarray[];
            } data;

            void main() {
                uint globalId = gl_GlobalInvocationID.x;
                if(globalId<256)
                    while(globalId<dftlength){
                        DFTData currentParticle = data.dftarray[globalId];
                        ivec2 storePos = ivec2(globalId,0);
                        imageStore(remotedftdOutput, storePos, vec4(currentParticle.left/256.0,currentParticle.right/256.0,0 ,1));
                        globalId+=256;
                    }
            }"
    }

    ShaderProgram {
        id: bufferShader
        vertexShaderCode:imageShader.vertexShaderCode 
    }

    ShaderProgram {
        id: flipbufferShader
        vertexShaderCode:imageShader.vertexShaderCode 
        fragmentShaderCode:"#version 130
            uniform sampler2D bufferOutput;
            in mediump vec2 qt_TexCoord0;
            out vec4 out_Color;
            void main() {
                out_Color=texture(bufferOutput,qt_TexCoord0);
            }"
    }

    ShaderProgram {
        id: imageShader
        vertexShaderCode: "#version 130
            #define FP highp

            attribute FP vec3 vertexPosition;
            varying FP vec3 worldPosition;
            uniform FP mat4 modelMatrix;
            uniform FP mat4 mvp;

            varying vec2 qt_TexCoord0;

            in vec2 vertexTexCoord;

            void main()
            {
            // Transform position, normal, and tangent to world coords
            worldPosition = vec3(modelMatrix * vec4(vertexPosition, 1.0));

            // Calculate vertex position in clip coordinates
            gl_Position = mvp * vec4(worldPosition, 1.0);
            qt_TexCoord0=vertexTexCoord; 
            }"
    }

    ShaderProgram {
        id: finalShader
        vertexShaderCode:imageShader.vertexShaderCode 
        fragmentShaderCode:"#version 130
            uniform sampler2D imageOutput;
            in mediump vec2 qt_TexCoord0;
            out vec4 out_Color;

            void main() {
                out_Color.a=1;
                if(qt_TexCoord0.x<0.5)
                    out_Color.rgb=texture(imageOutput,vec2(qt_TexCoord0.x*2,1-qt_TexCoord0.y)).rgb;
                else
                    out_Color.rgb=texture(imageOutput,vec2(qt_TexCoord0.x*2-1,1-qt_TexCoord0.y)).aaa;
            }"
    }

} 
