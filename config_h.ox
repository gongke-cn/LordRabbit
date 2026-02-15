ref "std/io"
ref "std/fs"
ref "std/path"
ref "./basic"
ref "./config"
ref "./log"

/*?
 *? Save macros to a configuration header file.
 *? @param name {String} The name of the configuration header file.
 */
public config_h: func(name = "config.h") {
    if !running() {
        return
    }

    path = get_path(name)

    sb = String.Builder()
    macro = basename(path).to_upper().replace(/[\.\-]/, "_")
    sb.append("#ifndef _{macro}_\n")
    sb.append("#define _{macro}_\n\n")
    for config.macro_dict.entries() as [mn, mv] {
        if mv == null {
            mv = "1"
        }

        sb.append("#define {mn} {mv}\n\n")
    }
    sb.append("#endif\n")

    new = sb.$to_str()

    if Path(path).exist {
        old = File.load_text(path)
    }

    if new != old {
        mkdir_p(dirname(path))
        File.store_text(path, new)
        stdout.puts(L"store \"{path}\"\n")
    }

    config.configh = path
}
