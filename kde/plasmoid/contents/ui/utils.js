function get_root() {
    var p_ui = plasmoid.file("ui")
    p_ui = p_ui.split('/')
    p_ui.pop(-1)
    return p_ui.join('/')
}

function get_scripts_root() {
    return get_root() + '/scripts'
}

function read_shader(name) {
    var path = get_root() + '/shaders/' + name
    return 'cat "' + path + '"'
}