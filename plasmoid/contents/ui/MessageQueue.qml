import QtQuick 2.0

/*
 * The length of this queue is 2. The queue rejects new 
 * messages before the images of old messages are loaded.
 */

Item{

    property variant imgsReady:pt0

    property variant imgsLoading:pt0

    function push(message){
        if(message.length<1){
            imgsReady=nt
            return
        }
        if(!imgsLoading.used)
            return
        imgsLoading.used=false
        var obj = JSON.parse(message)

        imgsLoading.s.source = 'data:' + obj.spectrum
        imgsLoading.w.source = 'data:' + obj.wave

        if(imgsLoading.ready){
            var p
            if(imgsLoading==pt0)p=pt1
            if(imgsLoading==pt1)p=pt0
            imgsReady=imgsLoading
            p.used=true
            imgsLoading=p
        }

    }

    PreloadingTextures{id:nt;audioAvailable:false}

    PreloadingTextures{id:pt0;onReadyChanged:{
        if(ready){
            imgsReady=pt0
            pt1.used=true
            imgsLoading=pt1
        }
    }}

    PreloadingTextures{id:pt1;onReadyChanged:{
        if(ready){
            imgsReady=pt1
            pt0.used=true
            imgsLoading=pt0
        }
    }}

}
