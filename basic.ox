ref "std/lang"
ref "std/path"
ref "json/json_schema"
ref "./config"
ref "./inner_tools"
ref "./log"

/*?
 *? @otype{ Rule The rule.
 *? @var srcs {[String]} Source files.
 *? @var dsts {[String]} Destination files.
 *? @var cmd {String} The generation command.
 *? @var phony {String} Phony rule name.
 *? @otype}
 *?
 *? @otype{ Install The installation job.
 *? @var src {String} The source file.
 *? @var srcdir {String} The source directory.
 *? @var dst {String} The destination file.
 *? @var dstdir {String} The destination directory.
 *? @var mode {String} The file mode.
 *? @var strip {Bool} Discard the symbols in the object.
 *? @var symlink {Bool} Is a symbol link or not.
 *? @otype}
 *?
 *? @otype{ InstallRule The installation rule.
 *? @var srcs {[String]} The source files.
 *? @var srcdirs {[String]} The source directories.
 *? @var instdir {String} The installation directory.
 *? @var mode {String} The file mode.
 *? @otype}
 *?
 *? @otype{ LinkInfo Libraries linked information.
 *? @var libdirs {[String]} Libraries lookup directories.
 *? @var libs {[String]} Linked libraries' names.
 *? @otype}
 */

//Get the current location.
public get_location: func() {
    stack = OX.stack()

    for stack as se {
        if se.filename ~ /lrbuild.ox$/i {
            return "\"{se.filename}\" {se.line}"
        }
    }
}

/*?
 *? Check if the generator is running.
 *? @return {Bool} The generator is running or not.
 */
public running: func {
    return config.job != Job.LISTOPT
}

/*?
 *? Get the real path.
 *? @param path {?String} The path defined in lrbuild.ox
 *? @return {?String} The real path.
 */
public get_path: func(path) {
    if path == null {
        return null
    }

    prefix = path[0]
    if prefix == "+" {
        return normpath("{config.outdir}/{config.currdir}/{path.slice(1)}")
    } else {
        return normpath("{config.currdir}/{path}")
    }
}

/*?
 *? Get the real path array.
 *? @param path {?String} The paths defined in lrbuild.ox
 *? @return {?String} The real paths array.
 */
public get_paths: func(paths) {
    if paths == null {
        return null
    }

    return paths.$iter().map((get_path($))).to_array()
}

/*?
 *? Get the output directory.
 *? @return {String} The output directory.
 */
public get_outdir: func {
    return config.outdir
}

/*?
 *? Get the current directory.
 *? @return {String} The current directory.
 */
public get_currdir: func {
    return config.currdir
}

/*?
 *? Get the installation directory.
 *? @return {String} The installation directory.
 */
public get_instdir: func {
    return config.instdir
}

/*?
 *? Get the current toolchain.
 *? @return {Toolchain} The current toolchain object.
 */
public toolchain: func {
    return config.toolchain
}

/*?
 *? Get the shell.
 *? @return {ShellCommand} The current used shell.
 */
public shell: func {
    return config.shell
}

/*?
 *? Get the compiler flags.
 *? @return {String} The compiler flags.
 */
public get_cflags: func {
    return config.cflags
}

/*?
 *? Get the linker flags.
 *? @return {String} The linker flags.
 */
public get_ldflags: func {
    return config.ldflags
}

/*?
 *? Get the macro definitions.
 *? @return {String} The macro definitions.
 */
public get_macros: func {
    if config.configh {
        return null
    }

    return config.macro_dict.entries().map(func([name, val]) {
        if val == null {
            return name
        } else {
            return "{name}={val}"
        }
    }).to_array()
}

/*?
 *? Get include header files.
 *? @return {[String]} The header files.
 */
public get_incs: func {
    r = [...config.incs]
    if config.configh {
        r.push(config.configh)
    }

    return r
}

/*?
 *? Get the header lookup directories.
 *? @return {[String]} The header lookup directories.
 */
public get_incdirs: func {
    return [...config.incdirs]
}

/*?
 *? Get the library lookup directory.
 *? @return {[String]} The library lookup directory.
 */
public get_libdirs: func {
    return [...config.libdirs]
}

/*?
 *? Get the linked libraries.
 *? @return {[String]} The linked libraries.
 */
public get_libs: func {
    return [...config.libs]
}

/*?
 *? Add a rule.
 *? @param rule {Rule} The rule to be added.
 */
public add_rule: func(rule) {
    if !running() {
        return
    }

    config.rules.push(rule)
}

/*?
 *? Add a phony product.
 *? @param prod {String} The phony product.
 */
public add_product: func(prod) {
    if !running() {
        return
    }

    config.products.push(prod)
}

//JSON schem of InstallRule.
install_rule_schema: JsonSchema({
    type: "object"
    properties: {
        srcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        srcdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
    }
    required: ["instdir"]
})

/*?
 *? Install files.
 *? @param job {InstallRule} Installation rule.
 */
public install: func(def) {
    if !running() {
        return
    }

    try {
        install_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    for def.srcs as src {
        fn = get_path(src)

        add_install({
            src: fn
            dstdir: "{get_instdir()}/{def.instdir}"
            mode: def.mode
        })
    }

    for def.srcdirs as sdir {
        dir = get_path(sdir)

        add_install({
            srcdir: dir
            dstdir: "{get_instdir()}/{def.instdir}"
            mode: def.mode
        })
    }
}

/*?
 *? Add an installation job.
 *? @param job {Install} The installation job.
 */
public add_install: func(job) {
    cmd = shell()

    if job.src && !job.symlink {
        config.products.push(job.src)
    }

    if config.install {
        config.install += "\n"
    }

    if job.symlink {
        config.install += cmd.symlink(job.src, job.dst)
    } else {
        config.install += cmd.install({
            src: job.src
            srcdir: job.srcdir
            dst: job.dst
            dstdir: job.dstdir
            mode: job.mode
            strip: job.strip
        })
    }

    if config.uninstall {
        config.uninstall += "\n"
    }

    if job.src {
        if job.dst {
            fn = job.dst
        } else {
            fn = "{job.dstdir}/{basename(job.src)}"
        }

        config.uninstall += cmd.rm(fn)
    } else {
        config.uninstall += cmd.rmdir(job.dstdir)
    }
}

//JSON schema of sub directories.
subdirs_schems: JsonSchema({
    type: "array"
    items: {
        type: "string"
    }
})

/*?
 *? Add subdirectories.
 *? @param dirs {[String]} The subdirectories.
 */
public subdirs: func(dirs) {
    try {
        subdirs_schems.validate_throw(dirs)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    for dirs as dir {
        sub = "{get_currdir()}/{dir}"

        run_lr_build(sub)
    }
}

/*?
 *? Configurate failed.
 *? @param msg {String} Message.
 *? 
 */
public failed: func(msg) {
    if !running() {
        return
    }

    throw Error("{get_location()}: {msg}")
}

//JSON schema of package information.
package_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        version: {
            type: "string"
        }
    }
    required: [
        "name"
        "version"
    ]
})

/*?
 *? Set the package information.
 *? @param def {Package} The package information.
 */
public package: func(def) {
    if !running() {
        return
    }

    try {
        package_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    config.package = def
}

/*?
 *? Get the current pakcage information.
 *? @return {Package} The package information.
 */
public get_package: func {
    return config.package
}

/*?
 *? Define a macro.
 *? @param name {String} Name of the macro.
 *? @param val {?String} Value of the macro.
 */
public define: func(name, val) {
    if !running() {
        return
    }

    config.macro_dict.add(name, val)
}

/*?
 *? Undefine a macro.
 *? @param name {String} Name of the macro.
 */
public undef: func(name) {
    if !running() {
        return
    }

    config.macro_dict.remove(name)
}

/*?
 *? Add a header lookup directory.
 *? @param dir {String} The directory.
 */
public add_incdir: func(dir) {
    if !running() {
        return
    }

    config.incdirs.add(get_path(dir))
}

/*?
 *? Add a library lookup directory.
 *? @param dir {String} The directory.
 */
public add_libdir: func(dir) {
    if !running() {
        return
    }

    config.libdirs.add(get_path(dir))
}

/*?
 *? Add a global include header file.
 *? @param hdr {String} The header file.
 */
public add_inc: func(hdr) {
    if !running() {
        return
    }

    config.incs.add(get_path(hdr))
}

/*?
 *? Add a global linked library.
 *? @param lib {String} The library name.
 */
public add_lib: func(lib) {
    if !running() {
        return
    }

    config.libs.add(lib)
}

/*?
 *? Add compiler flags.
 *? @param f {String} The flags.
 */
public add_cflags: func(f) {
    if !running() {
        return
    }

    if config.cflags == null {
        config.cflags = f
    } else {
        config.cflags += " {f}"
    }
}

/*?
 *? Add linker flags.
 *? @param f {String} The flags.
 */
public add_ldflags: func(f) {
    if !running() {
        return
    }

    if config.ldflags == null {
        config.ldflags = f
    } else {
        config.ldflags += " {f}"
    }
}

/*?
 *? Solve the linked libraries.
 *? @param libs {[String]} The linked libraries.
 *? @return {LinkInfo} The library linked information. 
 */
public solve_libs: func(libs) {
    li = {
        libs: []
        libdirs: []
        deplibs: []
    }

    for libs as lib {
        if lib[0] == "+" {
            lib = get_path(lib.slice(1))
            libdir = dirname(lib)
            libbase = basename(lib)

            li.libdirs.push(normpath("{get_outdir()}/{libdir}"))
            li.libs.push(libbase)
            li.deplibs.push(normpath("{get_outdir()}/{libdir}/lib{libbase}"))
        } else {
            li.libs.push(lib)
        }
    }

    return li
}

/*?
 *? Add a job.
 *? @param job {Function} The job function.
 */
public add_job: func(job) {
    if !running() {
        return
    }

    config.jobs.push(job)
}