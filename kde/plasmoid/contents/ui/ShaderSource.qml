import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    readonly property var cfg:plasmoid.configuration

    //Shader Source Reader
    property string src_shader1:""
    property string src_shader2:""
    property string src_body:""
    property string src_glsl_version:""
    property string shader_source:src_prepared?src_glsl_version+"\n"+src_shader1+"\n"+src_shader2+"\n"+src_body:""
    // Prevent generating unnecessary GLSL compiling error before all source files are prepared
    property bool src_prepared:src_shader1.length*src_shader2.length*src_body.length>0


    readonly property string sh_get_shader_list:'sh '+'"'+Utils.get_scripts_root()+'/get-shaders.sh'+'" '

    property var shader_list:[]
    property string shader_name:{
        if(cfg.randomShader && shader_list.length>0){
            return shader_list[parseInt(Math.random()*shader_list.length)]
        }
        return cfg.shader
    }

    engine: 'executable'
    connectedSources: [
        Utils.read_shader('husl-glsl.fsh'),
        Utils.read_shader('utils.fsh'),
        Utils.read_shader(shader_name),
        sh_get_shader_list
    ]

    onNewData:{
        if(sourceName==sh_get_shader_list){
            shader_list=data.stdout.substr(0,data.stdout.length-1).split('\n')
        }else if(sourceName==Utils.read_shader('husl-glsl.fsh'))
            src_shader1=data.stdout
        else if(sourceName==Utils.read_shader('utils.fsh'))
            src_shader2=data.stdout
        else if(sourceName==Utils.read_shader(shader_name)){
            var i=data.stdout.indexOf('\n')
            src_glsl_version=data.stdout.substr(0,i)
            src_body=data.stdout.substr(i,data.stdout.length)
        }
    }
}
