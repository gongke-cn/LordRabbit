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

    sb = String.Builder()
    for config.macro_dict.entries() as [mn, mv] {
        if mv == null {
            mv = "1"
        }

        sb.append("#define {mn} {mv}\n")
    }

    new = sb.$to_str()

    path = get_path(name)
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
