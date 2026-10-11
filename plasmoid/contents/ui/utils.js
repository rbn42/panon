.pragma library

// Absolute path of the package's contents directory.
const contentsRoot = decodeURIComponent(Qt.resolvedUrl("..").toString().replace(/^file:\/\//, '').replace(/\/$/, ''))

// Absolute path of a file inside the package's contents directory.
function packagePath(relativePath) {
    return contentsRoot + '/' + relativePath
}

// Where the python modules live.
const scriptsRoot = packagePath("scripts")

function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'"
}

// Returns a shell command running the python module inside contents/scripts.
function pythonCommand(module, args) {
    return 'cd ' + shellQuote(scriptsRoot) + ' && exec python3 -m ' + module
        + (args || []).map(arg => ' ' + shellQuote(arg)).join('')
}

// The audio back-ends, indexed by the backendIndex setting.
// id is the --backend argument of panon.backend.client.
const backends = [
    { id: 'pyaudio', name: 'PortAudio' },
    { id: 'soundcard', name: 'PulseAudio' },
    { id: 'fifo', name: 'fifo' },
]
