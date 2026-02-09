ref "std/system"
ref "std/path"
ref "std/path_conv"
ref "./linux"
ref "./config"

//Windows target.
public Windows: {
    //Name.
    name: "windows"
    //Suffix of executable program.
    exe_suffix: ".exe"
    //Suffix of static library.
    slib_suffix: ".a"
    //Suffix of dynamic library.
    dlib_suffix: ".dll.a"

    //Build dynamic library.
    build_dlib: func(def, objs, solve_dep_libs) {
        if def.version {
            dllbase = "lib{def.name}-{def.version}.dll"
        } else {
            dllbase = "lib{def.name}.dll"
        }

        dll = normpath("{get_outdir()}/{get_currdir()}/{dllbase}")
        lib = normpath("{get_outdir()}/{get_currdir()}/lib{def.name}.dll.a")

        tc = toolchain()

        if def.pcs {
            pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
        }

        li = solve_libs(def.libs)

        linkcmd = tc.objs2dlib({
            objs
            lib: dll
            slib: lib
            libdirs: [...li.libdirs, ...get_paths(def.libdirs), ...get_libdirs()]
            libs: [...li.libs, ...get_libs()]
            ldflags: "{def.ldflags} {pc_libs} {get_ldflags()}"
            cxx: def.cxx
        })

        cmd = shell()

        rule = {
            srcs: objs
            dsts: [dll, lib]
            cmd: ''
{{cmd.mkdir(dirname(dll))}}
{{cmd.mkdir(dirname(lib))}}
{{linkcmd}}
            ''
        }

        add_rule(rule)
        solve_dep_libs(rule, li.deplibs)

        if def.instdir != "none" {
            add_install({
                src: lib
                dst: normpath("{get_instdir()}/{def.instdir}/lib{def.name}.dll.a")
                mode: "0644"
            })
        }

        if def.exeinstdir != "none" {
            add_install({
                src: dll
                dst: normpath("{get_instdir()}/{def.instdir}/{dllbase}")
                mode: "0644"
                strip: true
            })
        }
    }
}