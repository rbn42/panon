import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    readonly property var cfg:plasmoid.configuration
    engine: 'executable'

    property bool ready:false

    readonly property string image_shader_source:build_source(['hsluv-glsl.fsh','utils.fsh','shadertoy-api-head.fsh',image_shader_name,'shadertoy-api-foot.fsh'],image_shader_name,arguments_json_name)
    readonly property string buffer_shader_source:build_source(['shadertoy-api-head.fsh',buffer_shader_name,'shadertoy-api-foot-buffer.fsh'],buffer_shader_name,arguments_json_name)

    readonly property string image_shader_name:{
        if(shader_name.endsWith('.frag'))return shader_name
        if(shader_name.endsWith('/'))return shader_name+'image.frag'
        return ''
    }
    readonly property string buffer_shader_name:shader_name.endsWith("/")?shader_name+"buffer.frag":""
    readonly property string arguments_json_name:shader_name.endsWith("/")?shader_name+"arguments.json":""

    function build_source(files,main_file,arguments_json_file){
        if(!ready)return ""
        if(!(main_file in files_content))return ""
        // Extract GLSL version
        var src_glsl_version=files_content[main_file].substr(0,files_content[main_file].indexOf("\n"))
        var content=files.reduce(function(acc,n){return acc+files_content[n]},"")
        content=content.replace("\n#version","\n////")

        // Load arguments
        if(arguments_json_file in files_content){
            var arguments_json=JSON.parse(files_content[arguments_json_file])

            var arg_map={}
            for(var index=0;index<arguments_json.length;index++){
                var name=arguments_json[index].name
                var value=arguments_json[index]["default"]
                if(!cfg.randomVisualEffect)
                    if(cfg.effectArgValues.length>index)
                        value=cfg.effectArgValues[index]
                arg_map["$"+name]=value
            }

            content=content.split("\n").map(function(line){
                var lst=line.split(" ")
                if(lst[0]!='#define')return line
                if(lst.length<3)return line
                if(lst[2][0]!="$")return line
                lst[2]=arg_map[lst[2]]
                return lst.join(" ")
            }).join("\n")
        }

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
