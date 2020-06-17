import Qt3D.Core 2.14
import Qt3D.Render 2.14
import Qt3D.Extras 2.14


Entity {

    property alias imageShaderSource:spe.imageShaderSource
    property alias bufferShaderSource:spe.bufferShaderSource

    property alias enable:spfg.enable
    property alias glDFT:spfg.glDFT

    property alias colorSpaceHSL:     colorSpaceHSLP.value
    property alias colorSpaceHSLuv:   colorSpaceHSLuvP.value

    property int hueFrom
    property int hueTo
    property int saturation
    property int lightness

    property alias iTime:             iTimeP.value
    property alias iTimeDelta:        iTimeDeltaP.value
    property alias iBeat:             iBeatP.value
    property alias iFrame: iFrameP.value 

    property variant iMouse

    property int gravity
    property int sceneWidth
    property int sceneHeight
    readonly property int gravityWidth:gravity<=2?sceneWidth:sceneHeight
    readonly property int gravityHeight:gravity<=2?sceneHeight:sceneWidth

    property var npdft
    readonly property int npdftLength:{npdft?npdft.length/2:10}

    property var newWaveData
    property int newWaveLength:10 

    readonly property int waveBufferLength:44100*4

    function push(arr){
        newWaveData=arr ; 
        newWaveLength=arr.length/2;
    }

    components: [
        RenderSettings {
            SpFrameGraph{
                id:spfg
                bufferOutput:bufferOutputP.value
                flipbufferOutput:iChannel2P.value
                imageOutput:imageOutputP.value
            }
            renderPolicy:RenderSettings.OnDemand // RenderSettings.Always
        }
    ]

    Entity {
        components: [
            PlaneMesh {},

            ComputeCommand {},

            Material {
                id:spm
                effect: SpEffect{id:spe}

                parameters: [
                    // Remote DFT data
                    Parameter {name: "Npdft";value: Buffer {data:npdft}},
                    Parameter {name: "npdftLength";value: npdftLength;},
                    // Remote wave data
                    Parameter {name: "NewWaveData";value: Buffer {data:newWaveData}},
                    Parameter {name: "newWaveLength";value: newWaveLength;},
                    // Wave buffer
                    Parameter {name: "WaveBuffer";value: Buffer {data:new Int32Array(waveBufferLength*2)}},
                    Parameter {name: "Maxwave";value: Buffer {data:new Int32Array(100)}},
                    Parameter {name: "waveBufferLength";value:waveBufferLength;},

                    Parameter{id:colorSpaceHSLP;name:"colorSpaceHSL";},
                    Parameter{id:colorSpaceHSLuvP;name:"colorSpaceHSLuv";},
                    Parameter{name:"hueFrom";value:hueFrom;},
                    Parameter{name:"hueTo";value:hueTo;},
                    Parameter{name:"saturation";value:saturation;},
                    Parameter{name:"lightness";value:lightness;},
                    Parameter{id:iTimeP;name:"iTime";},
                    Parameter{id:iTimeDeltaP;name:"iTimeDelta";},
                    Parameter{id:iBeatP;name:"iBeat";},
                    Parameter{name: "iResolution";value:Qt.vector3d(gravityWidth,gravityHeight,0);},
                    Parameter{id:iFrameP;name: "iFrame";},
                    Parameter {name: "gravity";value:gravity},

                    Parameter {name: "iChannelResolution1";value:Qt.vector3d(iChannel1P.value.width,iChannel1P.value.height,0);},
                    Parameter {
                        id:iChannel1P
                        name: "iChannel1"
                        value:Texture2D {
                            width:glDFT?400:npdftLength;format: Texture.RGBA8_UNorm;
                            magnificationFilter: Texture.Linear
                            minificationFilter: Texture.LinearMipMapLinear
                            generateMipMaps: true
                            maximumAnisotropy: 16.0
                            wrapMode {
                                x: WrapMode.ClampToEdge
                                y: WrapMode.ClampToEdge
                            }
                        }
                    },

                    Parameter {name: "iChannelResolution2";value:Qt.vector3d(iChannel2P.value.width,iChannel2P.value.height,0);},
                    Parameter {
                        id:iChannel2P
                        name: "iChannel2"
                        value:Texture2D {
                            width: gravityWidth
                            height: gravityHeight
                            format: Texture.RGBA8_UNorm
                            magnificationFilter: Texture.Linear
                            minificationFilter: Texture.LinearMipMapLinear
                            generateMipMaps: true
                            maximumAnisotropy: 16.0
                            wrapMode {
                                x: WrapMode.ClampToEdge
                                y: WrapMode.ClampToEdge
                            }
                        }
                    },
                    Parameter {
                        id:bufferOutputP
                        name: "bufferOutput"
                        value:Texture2D {
                            width: gravityWidth
                            height: gravityHeight
                            format: Texture.RGBA8_UNorm
                        }
                    },
                    Parameter {
                        id:imageOutputP
                        name:"imageOutput"
                        value:Texture2D {
                            width: sceneWidth
                            height: sceneHeight
                            format: Texture.RGBA8_UNorm
                        }
                    },
                    Parameter {
                        name: "remotedftdOutput"
                        value: ShaderImage {
                            texture:iChannel1P.value
                            access: ShaderImage.WriteOnly
                            format: ShaderImage.RGBA8_UNorm
                        }
                    }
                ]
            }
        ]
    }
}
