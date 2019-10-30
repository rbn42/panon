function get_scripts_root() {
    var p_ui = plasmoid.file("ui")
    p_ui = p_ui.split('/')
    p_ui.pop(-1)
    p_ui.push('scripts')
    return p_ui.join('/')
}

