import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils

PlasmaCore.DataSource {

    engine: 'executable'

    property var database:{'a':'b'}

    function read(path,obj){
        var cmd='cat '+Utils.get_root()+path //'/ui/main.qml'
        if(obj.ready)
            return database[cmd]
        if(cmd in database)
            return null
        database[cmd]=obj
        connectedSources.push(cmd)
        return null
    }

    connectedSources: []

    onNewData:{
        console.log(database[sourceName])
        var obj=database[sourceName]
        database[sourceName]=data.stdout
        obj.ready=true 
    }
}
