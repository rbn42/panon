import QtQuick

/*
 * The length of this queue is 2. The queue rejects new
 * messages before the images of old messages are loaded.
 */

Item {
    property PreloadingTextures imgsReady: textures0

    property PreloadingTextures imgsLoading: textures0

    function push(message) {
        if (message.length < 1) {
            imgsReady = silence
            return
        }
        if (!imgsLoading.used)
            return

        // When only spectrum data is enabled, the back-end sends the raw data uri
        // instead of JSON to reduce cpu usage. Detect the format per message, as a
        // previous back-end may still be sending the other format after the effect changed.
        const obj = message.startsWith('{') ? JSON.parse(message) : { spectrum: message }

        imgsLoading.used = false
        imgsLoading.spectrum.source = obj.spectrum ? 'data:' + obj.spectrum : ''
        imgsLoading.wave.source = obj.wave ? 'data:' + obj.wave : ''
        imgsLoading.beat = obj.beat ?? 0

        // Images may be loaded synchronously, in which case ready never changes.
        if (imgsLoading.ready)
            loaded(imgsLoading)
    }

    function loaded(textures) {
        imgsReady = textures
        imgsLoading = textures === textures0 ? textures1 : textures0
        imgsLoading.used = true
    }

    PreloadingTextures { id: silence; audioAvailable: false }

    PreloadingTextures { id: textures0; onReadyChanged: if (ready) loaded(textures0) }

    PreloadingTextures { id: textures1; onReadyChanged: if (ready) loaded(textures1) }

}
