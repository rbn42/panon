import Qt3D.Core 2.14
import Qt3D.Render 2.14

Viewport {

    //property alias dftOutput: dftOutput.texture
    property alias bufferOutput: bufferOutput.texture
    property alias flipbufferOutput: flipbufferOutput.texture
    property alias imageOutput: imageOutput.texture

    property bool enable:true
    property bool glDFT:true

    normalizedRect: Qt.rect(0.0, 0.0, 1.0, 1.0)

    RenderSurfaceSelector {
        TechniqueFilter {
            matchAll: [ FilterKey { name: "tech"; value: enable?"run":"stop" } ]
            
            DispatchCompute {
                RenderPassFilter {
                    matchAny: [ FilterKey { name: "pass"; value: glDFT?"gldftpass":"remotedftpass" } ]
                }
            }

            RenderPassFilter {
                matchAny: [ FilterKey { name: "pass"; value: "bufferpass" } ]
                RenderTargetSelector {
                    target: RenderTarget {
                        attachments: [
                            RenderTargetOutput {
                                id:bufferOutput
                                attachmentPoint: RenderTargetOutput.Color0
                            }
                        ]
                    }
                    ClearBuffers {
                        buffers: ClearBuffers.ColorDepthBuffer
                        CameraSelector {
                            camera:SpCamera{}
                        }
                    }
                }
            }

            RenderPassFilter {
                matchAny: [ FilterKey { name: "pass"; value: "flipbufferpass" } ]
                RenderTargetSelector {
                    target: RenderTarget {
                        attachments: [
                            RenderTargetOutput {
                                id:flipbufferOutput
                                attachmentPoint: RenderTargetOutput.Color0
                            }
                        ]
                    }
                    ClearBuffers {
                        buffers: ClearBuffers.ColorDepthBuffer
                        CameraSelector {
                            camera:SpCamera{}
                        }
                    }
                }
            }

            RenderPassFilter {
                matchAny: [ FilterKey { name: "pass"; value: "imagepass" } ]
                RenderTargetSelector {
                    target: RenderTarget {
                        attachments: [
                            RenderTargetOutput {
                                id:imageOutput
                                attachmentPoint: RenderTargetOutput.Color0
                            }
                        ]
                    }
                    ClearBuffers {
                        buffers: ClearBuffers.ColorDepthBuffer
                        CameraSelector {
                            camera:SpCamera{}
                        }
                    }
                }
            }

            RenderPassFilter {
                matchAny: [ FilterKey { name: "pass"; value: "finalpass" } ]
                ClearBuffers {
                    buffers: ClearBuffers.ColorDepthBuffer
                    CameraSelector {
                        camera:SpCamera{}
                    }
                }
            }
        }
    }
}

