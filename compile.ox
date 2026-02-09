ref "std/path"
ref "json/json_schema"
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

    if def.pcs {
        pc_cflags = def.pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")
    }

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

            if !(src ~ /\.(c|cpp|cxx|c\+\+)$/) {
                continue
            }

            cmd = shell()

            compilecmd = tc.c2obj({
                src
                obj
                dep
                macros
                incdirs
                incs
                cflags
                pic: def.pic
            })

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

lib_dict: Dict()

//Add a library.
add_lib: func(name, lib) {
    ent = lib_dict.get(name)
    if !ent {
        ent = []

        lib_dict.add(name, ent)
    }

    ent.push(lib)
}

//Solve the dependent libraries.
solve_dep_libs: func(rule, deplibs) {
    loc = get_location()

    add_job(func {
        libs = []

        for deplibs as lib {
            ent = lib_dict.get(lib)
            if !ent {
                throw Error(L"{loc}: library \"{lib}\" is not defined")
            }

            libs.[...ent]
        }

        rule.srcs = [...rule.srcs, ...libs]
    })
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

    //Add link job.
    tc = toolchain()

    if def.pcs {
        pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
    }

    ldflags = "{def.ldflags} {pc_libs} {get_ldflags()}"
    li = solve_libs(def.libs)
    libdirs = [...li.libdirs, ...get_paths(def.libdirs), ...get_libdirs()]
    libs = [...li.libs, ...get_libs()]

    exe = normpath("{get_outdir()}/{get_currdir()}/{def.name}{tc.target.exe_suffix}")

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
        srcs: objs
        dsts: [exe]
        cmd: ''
{{cmd.mkdir(dirname(exe))}}
{{linkcmd}}
        ''
    }

    add_rule(rule)
    solve_dep_libs(rule, li.deplibs)

    if def.instdir != "none" {
        add_install({
            src: exe
            dst: normpath("{get_instdir()}/{def.instdir}/{def.name}{tc.target.exe_suffix}")
            mode: "0755"
            strip: true
        })
    }
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

    sdef = {...def}
    sdef.pic = true

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

    libname = normpath("{get_outdir()}/{get_currdir()}/lib{def.name}")
    lib = "{libname}{tc.target.slib_suffix}"
    add_lib(libname, lib)

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
        //Add objects.
        objs = add_objs(def, "{def.name}-dlib-")
    }

    //Add dynamic library job.
    tc = toolchain()

    def.cxx = has_cxx(def.srcs)

    libname = normpath("{get_outdir()}/{get_currdir()}/lib{def.name}")
    lib = "{libname}{tc.target.dlib_suffix}"
    add_lib(libname, lib)

    tc.target.build_dlib(def, objs, solve_dep_libs)
}