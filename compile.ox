ref "std/path"
ref "json/json_schema"
ref "json/json"
ref "./basic"
ref "./log"

/*?
 *? @lib Tool functions can be invoked in "lrbuild.ox"
 *?
 *? @otype{ ExeRule Executable program building rule.
 *? @var name {String} Name of the executable program.
 *? @var srcs {[String]} Source files of the executable program.
 *? @var objs {[String]} Extra object files of the executable program.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var incs {[String]} Header files.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var pcs {[String]} Linked pkg-config modules.
 *? @var instdir {String} Installation directory.
 *? "none" means this program will not be installed.
 *? @otype}
 *?
 *? @otype{ LibRule Library building rule.
 *? @var name {String} Name of the executable program.
 *? @var srcs {[String]} Source files of the executable program.
 *? @var objs {[String]} Extra object files of the executable program.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var incs {[String]} Header files.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var pcs {[String]} Linked pkg-config modules.
 *? @var instdir {String} Installation directory.
 *? "none" means this library will not be installed.
 *? @var exeinstdir {String} Executable program's installation directory.
 *? @var pic {Bool} Enable position indenpent code.
 *? @var version {String} The version number of the dynamic library.
 *? @otype}
 */

//Check if the source files has C++ file.
has_cxx: func(srcs) {
    for srcs as src {
        if src ~ /\.(cpp|cxx|c\+\+)$/i {
            return true
        }
    }

    return false
}

//Add objects.
add_objs: func(def, prefix) {
    tc = toolchain()

    pcs = [...get_pcs(), ...def.pcs]

    pc_cflags = pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")

    objs = []
    srcs = []
    for def.srcs as src {
        srcs.push(get_path(src))

        if src[0] == "+" {
            src = src.slice(1)
        }

        srcdir = dirname(src)
        srcbase = basename(src)
        objbase = srcbase.replace(/\.(c|cpp|cxx|c\+\+)$/i, "\.o")
        objname = "{prefix}{objbase}"
        objs.push(normpath("{get_outdir()}/{get_currdir()}/{objname}"))
    }

    incdirs = [...get_paths(def.incdirs), ...get_incdirs()]
    cflags = "{def.cflags} {pc_cflags} {get_cflags()}"

    //Add objects.
    add_job(func {
        macros = [...def.macros, ...get_macros()]
        incs = [...def.incs, ...get_incs()]

        for i = 0; i < srcs.length; i += 1 {
            src = srcs[i]
            obj = objs[i]
            dep = obj.replace(/\.o$/, ".dep")

            if src ~ /\.(cpp|cxx|c\+\+)$/ {
                is_cxx = true
            } elif src ~ /\.c$/ {
                is_cxx = false
            } else {
                continue
            }

            cmd = shell()

            objdef = {
                src
                obj
                dep
                macros
                incdirs
                incs
                cflags
                pic: def.pic
            }

            if is_cxx {
                compilecmd = tc.cxx2obj(objdef)
            } else {
                compilecmd = tc.c2obj(objdef)
            }

            add_rule({
                srcs: [src]
                dsts: [obj, dep]
                cmd: ''
{{cmd.mkdir(dirname(obj))}}
{{compilecmd}}
                ''
            })
        }
    })

    objs.[...get_paths(def.objs)]

    return objs
}

//Libraries dictionary.
lib_dict: Dict()

//Split libraries to external and internal array.
split_libs: func(libs) {
    external = []
    internal = []
    for libs as lib {
        if lib[0] == "+" {
            internal.push(get_path(lib))
        } else {
            external.push(lib)
        }
    }

    return {internal, external}
}

//Get link information.
get_link_info: func(def, objs) {
    li = {
        srcs: [...objs]
        ldflags: def.ldflags
        pcs: Set().[...def.pcs]
        libdirs: Set().[...get_paths(def.libdirs)]
        libs: Set()
    }

    split_libs(def.libs) => {internal: li.internal_libs, external: li.external_libs}

    return li
}

//Solve link information.
solve_link_info: func(li, internal_libs) {
    for internal_libs as lib {
        li.libdirs.add(dirname(lib))
        li.libs.add(basename(lib))

        ent = lib_dict[lib]
        if !ent {
            throw Error("cannot find library \"{lib}\"")
        } else {
            li.pcs.[...ent.def.pcs]
            li.libdirs.[...ent.def.libdirs]
            li.libs.[...li.external_libs, ...ent.def.external_libs]
            li.srcs.[...ent.targets]

            if ent.def.ldflags {
                li.ldflags = "{li.ldflags} {ent.def.ldflags}"
            }

            solve_link_info(li, ent.def.internal_libs)
        }
    }
}

//Add a library.
add_lib: func(name, libpath, def) {
    ent = lib_dict.get(name)
    if !ent {
        ent = {targets:[]}

        lib_dict.add(name, ent)
    }

    split_libs(def.libs) => {internal: internal_libs, external: external_libs}

    ent.targets.push(libpath)
    ent.def = {
        pcs: def.pcs
        ldflags: def.ldflags
        libdirs: get_paths(def.libdirs)
        internal_libs
        external_libs
    }
}

//JSON schema of ExeRule.
exe_rule_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        srcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        objs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        cflags: {
            type: "string"
        }
        ldflags: {
            type: "string"
        }
        incdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        macros: {
            type: "array"
            items: {
                type: "string"
            }
        }
        libdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        libs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        pcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
    }
    required: [
        "name"
    ]
})

 /*?
 *? Add an executable program.
 *? @param def {ExeRule} Executable program building rule.
 */
public build_exe: func(def) {
    if !running() {
        return
    }

    //Validate the parameter.
    try {
        exe_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if !def.instdir {
        def.instdir = "bin"
    }

    //Add objects.
    objs = add_objs(def, "{def.name}-exe-")

    //Add installation job.
    tc = toolchain()
    exe = normpath("{get_outdir()}/{get_currdir()}/{def.name}{tc.target.exe_suffix}")

    if def.instdir != "none" {
        add_install({
            src: exe
            dst: normpath("{get_instdir()}/{def.instdir}/{def.name}{tc.target.exe_suffix}")
            mode: "0755"
            strip: true
        })
    }

    add_product(exe)

    //Add link job.
    li = get_link_info(def, objs)

    add_job(func {
        solve_link_info(li, li.internal_libs)

        pcs = [...get_pcs(), ...li.pcs]
        pc_libs = pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
        ldflags = "{li.ldflags} {pc_libs} {get_ldflags()}"
        libdirs = [...li.libdirs, ...get_libdirs()]
        libs = [...li.libs, ...get_libs()]

        cmd = shell()

        linkcmd = tc.objs2exe({
            objs
            exe
            ldflags
            libdirs
            libs
            cxx: has_cxx(def.srcs)
        })

        rule = {
            srcs: li.srcs
            dsts: [exe]
            cmd: ''
    {{cmd.mkdir(dirname(exe))}}
    {{linkcmd}}
            ''
        }

        add_rule(rule)
    })
}

//JSON schema of LibRule.
lib_rule_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        srcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        objs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        cflags: {
            type: "string"
        }
        ldflags: {
            type: "string"
        }
        incdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        macros: {
            type: "array"
            items: {
                type: "string"
            }
        }
        libdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        libs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        pcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
        exeinstdir: {
            type: "string"
        }
        pic: {
            type: "boolean"
        }
    }
    required: [
        "name"
    ]
})

/*?
 *? Add a library.
 *? @param def {LibRule} Library building rule.
 */
public build_lib: func(def) {
    if !running() {
        return
    }

    //Validate the parameter.
    try {
        lib_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if !def.instdir {
        def.instdir = "lib"
    }

    if def.instdir == "none" {
        def.exeinstdir = "none"
    } elif !def.exeinstdir {
        def.exeinstdir = "bin"
    }

    def.pic = true

    sdef = {...def}

    objs = add_objs(def, "{def.name}-lib-")

    build_slib(sdef, objs)
    build_dlib(def, objs)
}

/*?
 *? Add a static library.
 *? @param def {LibRule} Library building rule.
 */
public build_slib: func(def, objs) {
    if !running() {
        return
    }

    //Validate the parameter.
    try {
        lib_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if !def.instdir {
        def.instdir = "lib"
    }

    if objs == null {
        //Add objects.
        objs = add_objs(def, "{def.name}-slib-")
    }

    //Add static library job.
    tc = toolchain()

    libname = normpath("{get_outdir()}/{get_currdir()}/{def.name}")
    lib = normpath("{get_outdir()}/{get_currdir()}/lib{def.name}{tc.target.slib_suffix}")
    add_lib(libname, lib, def)

    cmd = shell()

    slibcmd = tc.objs2slib({
        objs
        lib
    })

    add_rule({
        srcs: objs
        dsts: [lib]
        cmd: ''
{{cmd.mkdir(dirname(lib))}}
{{slibcmd}}
        ''
    })

    if def.instdir != "none" {
        add_install({
            src: lib
            dst: normpath("{get_instdir()}/{def.instdir}/{def.name}{tc.target.slib_suffix}")
            mode: "0644"
        })
    }

    add_product(lib)
}

/*?
 *? Add a dynamic library.
 *? @param def {LibRule} Library building rule.
 */
public build_dlib: func(def, objs) {
    if !running() {
        return
    }

    //Validate the parameter.
    try {
        lib_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if !def.instdir {
        def.instdir = "lib"
    }

    if def.instdir == "none" {
        def.exeinstdir = "none"
    } elif !def.exeinstdir {
        def.exeinstdir = "bin"
    }

    if objs == null {
        def.pic = true

        //Add objects.
        objs = add_objs(def, "{def.name}-dlib-")
    }

    //Add dynamic library job.
    tc = toolchain()

    libname = normpath("{get_outdir()}/{get_currdir()}/{def.name}")
    lib = normpath("{get_outdir()}/{get_currdir()}/lib{def.name}{tc.target.dlib_suffix}")
    add_lib(libname, lib, def)

    li = get_link_info(def, objs)
    li.{
        toolchain: tc
        target: lib
        name: def.name
        version: def.version
        cxx: has_cxx(def.srcs)
        objs
        instdir: def.instdir
    }

    add_job(func {
        solve_link_info(li, li.internal_libs)

        tc.target.build_dlib(li)
    })
}
