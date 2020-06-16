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
                    filterKeys: [FilterKey { name: "pass"; value: "dft" } ]
                    shaderProgram: dftShader
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
        id: dftShader
        vertexShaderCode:imageShader.vertexShaderCode 
        fragmentShaderCode: "#version 130
            void main()
            {
                gl_FragColor.b=0.5;
                gl_FragColor.a=1;

            }"
    }

    ShaderProgram {
        id: remotedftShader
        computeShaderCode:"#version 430
            uniform int dftlength;
            writeonly uniform image2D remotedftdOutput;
            layout (local_size_x = 128) in;
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
                if(globalId<128)
                    while(globalId<dftlength){
                        DFTData currentParticle = data.dftarray[globalId];
                        ivec2 storePos = ivec2(globalId,0);
                        imageStore(remotedftdOutput, storePos, vec4(currentParticle.left/256.0,currentParticle.right/256.0,0 ,1));
                        globalId+=128;
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
