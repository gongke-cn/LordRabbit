ref "std/path"
ref "std/lang"
ref "std/char"
ref "std/io"
ref "./log"
ref "./config"

//Run the "lrbuild.ox" in the directory.
public run_lr_build: func(dn) {
    path = normpath("{dn}/lrbuild.ox")

    st = Path(path)
    if !st.exist {
        throw NullError(L"cannot find \"{path}\"")
    }

    if st.format != Path.FMT_REG {
        throw TypeError(L"\"{path}\" is not a regular file")
    }

    stdout.puts(L"load \"{path}\"\n")

    file = OX.file(path)

    //Store old settings.
    old_toolchain = config.toolchain
    old_currdir = config.currdir
    old_package = config.package

    config.buildfiles.push(path)
    config.currdir = normpath(dn)
    
    file(config)

    //Restore old settings.
    config.toolchain = old_toolchain
    config.currdir = old_currdir
    config.package = old_package
}

//Get the full pathname.
public get_full_path: func(path) {
    if path == null {
        return null
    }

    prefix = path[0]
    if prefix != "+" && prefix != "-" {
        prefix = null
    } else {
        path = path.slice(1)
    }

    if prefix == null {
        if (path.char_at(0) == '/') ||
                (isalpha(path.char_at(0)) && path.char_at(1) == ':') {
        } else {
            path = "{config.currdir}/{path}"
        }
    }

    return "{prefix}{normpath(path)}"
}

//Get the real pathname.
public get_real_path: func(path) {
    if path == null {
        return null
    }

    prefix = path[0]
    if prefix == "+" {
        return normpath("{config.outdir}/{path.slice(1)}")
    } elif prefix == "-" {
        return normpath("{config.intermediate()}/{path.slice(1)}")
    } else {
        return path
    }
}

//Get the command line of the generator.
public get_gen_cmd_line: func(def) {
    return def.cmd.replace(/\$(@|<|^|[0-9]+|\$)/, func(m) {
        case m.$to_str() {
        "$@" {
            return get_real_path(def.path)
        }
        "$<" {
            return get_real_path(def.srcs[0])
        }
        "$^" {
            return def.srcs.$iter().map((get_real_path($))).$to_str(" ")
        }
        "$$" {
            return "$"
        }
        * {
            id = Number(m.slice(1))
            return get_real_path(def.srcs[id])
        }
        }
    })
}

//Register a toolchain.
public register_toolchain: func(tc, name) {
    config.toolchains[name] = tc
}

//Register a generator.
public register_generator: func(gen, name) {
    config.generators[name] = gen
}