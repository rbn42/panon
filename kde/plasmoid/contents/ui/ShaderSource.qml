import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    readonly property var cfg:plasmoid.configuration
    engine: 'executable'

    property bool ready:false

    readonly property string image_shader_source:build_source(['hsluv-glsl.fsh','utils.fsh','shadertoy-api-head.fsh',image_shader_name,'shadertoy-api-foot.fsh'],image_shader_name)
    readonly property string buffer_shader_source:build_source(['shadertoy-api-head.fsh',buffer_shader_name,'shadertoy-api-foot-buffer.fsh'],buffer_shader_name)

    readonly property string image_shader_name:{
        if(shader_name.endsWith('.frag'))return shader_name
        if(shader_name.endsWith('/'))return shader_name+'image.frag'
        return ''
    }
    readonly property string buffer_shader_name:{
        if(shader_name.endsWith('/'))return shader_name+'buffer.frag'
        return ''
    }

    function build_source(files,main_file){
        if(!ready)return ""
        if(!(main_file in files_content))return ""
        // Extract GLSL version
        var src_glsl_version=files_content[main_file].substr(0,files_content[main_file].indexOf("\n"))
        var content=files.reduce(function(acc,n){return acc+files_content[n]},"")
        content=content.replace("\n#version","\n////")
        return src_glsl_version+"\n"+content
    }

    property var file_list:[]
    //Shader Source Reader
    readonly property var file_list_reader:file_list.map(function(n){return Utils.read_shader(n)})
    readonly property var files_content:new Map()

    property var shader_list:[]
    readonly property string shader_name:(shader_list.length>0&&cfg.randomVisualEffect)?shader_list[parseInt(Math.random()*shader_list.length)]:cfg.visualEffect

    readonly property string sh_get_shader_list:'sh '+'"'+Utils.get_scripts_root()+'/get-shaders.sh'+'" '
    readonly property string sh_get_file_list:'sh '+'"'+Utils.get_scripts_root()+'/get-all-shader-files.sh'+'" '
    connectedSources: shader_list.length*file_list.length<1 ?[sh_get_file_list, sh_get_shader_list]:file_list_reader

    onNewData:{

        if(sourceName==sh_get_shader_list){
            shader_list=data.stdout.substr(0,data.stdout.length-1).split('\n')
        }else if(sourceName==sh_get_file_list){
            file_list=data.stdout.substr(0,data.stdout.length-1).split('\n')
        }else{
            for(var index=0;index<file_list.length;index++){
                if(sourceName==file_list_reader[index]){
                    files_content[file_list[index]]=data.stdout
                    break
                }
            }
        }

        // Prevent generating unnecessary GLSL compiling error before all source files are prepared
        ready=file_list.reduce(function(acc,n){return acc && (n in files_content)}, file_list.length>0)
    }
}
