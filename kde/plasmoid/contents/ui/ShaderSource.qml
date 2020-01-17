import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    readonly property var cfg:plasmoid.configuration
    engine: 'executable'

    property string image_shader_source:''
    property string buffer_shader_source:''
    property string texture_uri:''

    readonly property string cmd:'python3'
        + ' "'+Utils.get_scripts_root()+'/build_shader_source.py'+'"'
        + (cfg.randomVisualEffect?' --random-effect':'')
        + ' --effect-name="'+cfg.visualEffect.replace('"','\\"').replace('$','\\$')+'"'
        + ' '+cfg.effectArgValues.map(function(s){return '"'+s.replace('"','\\"').replace('$','\\$')+'"'}).join(' ')

    connectedSources: [cmd]

    onNewData:{
        if(cfg.debugBackend){
            console.log(cmd)
            console.log(data.stderr)
        }
        var obj=JSON.parse(data.stdout);
        image_shader_source=obj.image_shader
        buffer_shader_source=obj.buffer_shader
        texture_uri=obj.texture
    }
}
