import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    //Shader Source Reader
    property string src_shader1:""
    property string src_shader2:""
    property string src_body:""
    property string src_glsl_version:""
    property string shader_source:src_prepared?src_glsl_version+"\n"+src_shader1+"\n"+src_shader2+"\n"+src_body:""
    // Prevent generating unnecessary GLSL compiling error before all source files are prepared
    property bool src_prepared:src_shader1.length*src_shader2.length*src_body.length>0

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
        else if(sourceName==Utils.read_shader(plasmoid.configuration.shader)){
            var i=data.stdout.indexOf('\n')
            src_glsl_version=data.stdout.substr(0,i)
            src_body=data.stdout.substr(i,data.stdout.length)
        }
    }
}
