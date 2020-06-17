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
                    filterKeys: [FilterKey { name: "pass"; value: "remotewavepass" } ]
                    shaderProgram: remotewaveShader
                },
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

    FileReader{id:fileReader}

    ShaderProgram {
        id: remotewaveShader
        property bool ready:false
        computeShaderCode:fileReader.read('/shaders/qt3d/remotewave.comp',remotewaveShader)
    }

    ShaderProgram {
        id: gldftShader
        property bool ready:false
        computeShaderCode:fileReader.read('/shaders/qt3d/gldft.comp',gldftShader)
    }

    ShaderProgram {
        id: remotedftShader
        property bool ready:false
        computeShaderCode:fileReader.read('/shaders/qt3d/remotedft.comp',remotedftShader)
    }

    ShaderProgram {
        id: bufferShader
        vertexShaderCode:imageShader.vertexShaderCode 
    }

    ShaderProgram {
        id: flipbufferShader
        property bool ready:false
        vertexShaderCode:imageShader.vertexShaderCode 
        fragmentShaderCode:fileReader.read('/shaders/qt3d/flipbuffer.frag',flipbufferShader)
    }

    ShaderProgram {
        id: imageShader
        property bool ready:false
        vertexShaderCode:fileReader.read('/shaders/qt3d/default.vert',imageShader)
    }

    ShaderProgram {
        id: finalShader
        vertexShaderCode:imageShader.vertexShaderCode 
        property bool ready:false
        fragmentShaderCode:fileReader.read('/shaders/qt3d/final.frag',finalShader)
    }

} 
