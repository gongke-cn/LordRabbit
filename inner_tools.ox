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

//Register a toolchain.
public register_toolchain: func(tc, name) {
    config.toolchains[name] = tc
}

//Register a generator.
public register_generator: func(gen, name) {
    config.generators[name] = gen
}
