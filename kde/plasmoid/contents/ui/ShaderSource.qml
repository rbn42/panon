import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    //Shader Source Reader
    property string src_shader1
    property string src_shader2
    property string src_shader3
    property string shader_source:"#version 400\n"+src_shader1+"\n"+src_shader2+"\n"+src_shader3

    engine: 'executable'
    connectedSources: [
        Utils.read_shader('husl-glsl.fsh'),
        Utils.read_shader('utils.fsh'),
        Utils.read_shader(plasmoid.configuration.shader)
    ]

    onNewData:{
        if(sourceName==Utils.read_shader('husl-glsl.fsh'))
            src_shader1=data.stdout
        else if(sourceName==Utils.read_shader('utils.fsh'))
            src_shader2=data.stdout
        else if(sourceName==Utils.read_shader(plasmoid.configuration.shader))
            src_shader3=data.stdout
    }
}
