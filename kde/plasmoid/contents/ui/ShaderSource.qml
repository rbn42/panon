import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    readonly property var cfg:plasmoid.configuration

    //Shader Source Reader
    property string src_head1:""
    property string src_head2:""
    property string src_head3:""
    property string src_body:""
    property string src_foot:""
    property string src_glsl_version:""
    property string shader_source:src_prepared?src_glsl_version+"\n"+src_head1+"\n"+src_head2+"\n"+src_head3+"\n"+src_body+"\n"+src_foot:""
    // Prevent generating unnecessary GLSL compiling error before all source files are prepared
    property bool src_prepared:src_head1.length*src_head2.length*src_head3.length*src_body.length*src_foot.length>0


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
        Utils.read_shader('shadertoy-api-head.fsh'),
        Utils.read_shader(shader_name),
        Utils.read_shader('shadertoy-api-foot.fsh'),
        sh_get_shader_list
    ]

    onNewData:{
        if(sourceName==sh_get_shader_list){
            shader_list=data.stdout.substr(0,data.stdout.length-1).split('\n')
        }else if(sourceName==Utils.read_shader('husl-glsl.fsh'))
            src_head1=data.stdout
        else if(sourceName==Utils.read_shader('utils.fsh'))
            src_head2=data.stdout
        else if(sourceName==Utils.read_shader('shadertoy-api-head.fsh'))
            src_head3=data.stdout
        else if(sourceName==Utils.read_shader('shadertoy-api-foot.fsh'))
            src_foot=data.stdout
        else if(sourceName==Utils.read_shader(shader_name)){
            var i=data.stdout.indexOf('\n')
            src_glsl_version=data.stdout.substr(0,i)
            src_body=data.stdout.substr(i,data.stdout.length)
        }
    }
}
