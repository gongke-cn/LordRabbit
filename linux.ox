ref "std/path"
ref "./log"
ref "./basic"

//Linux target.
public Linux: {
    //Name.
    name: "linux"
    //Suffix of executable program.
    exe_suffix: ""
    //Suffix of static library.
    slib_suffix: ".a"
    //Suffix of dynamix library.
    dlib_suffix: ".so"

    //Build dynamic library.
    build_dlib: func(def, objs, solve_dep_libs) {
        if def.version {
            libbase = "lib{def.name}{this.dlib_suffix}.{def.version}"
        } else {
            libbase = "lib{def.name}{this.dlib_suffix}"
        }

        lib = normpath("{get_outdir()}/{get_currdir()}/{libbase}")

        tc = toolchain()
        cmd = shell()

        if def.pcs {
            pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
        }

        li = solve_libs(def.libs)

        linkcmd = tc.objs2dlib({
            objs
            lib
            libdirs: [...li.libdirs, ...get_paths(def.libdirs), ...get_libdirs()]
            libs: [...li.libs, ...get_libs()]
            ldflags: "{def.ldflags} {pc_libs} {get_ldflags()}"
            cxx: def.cxx
        })

        rule = {
            srcs: objs
            dsts: [lib]
            cmd: ''
{{cmd.mkdir(dirname(lib))}}
{{linkcmd}}
            ''
        }

        add_rule(rule)
        solve_dep_libs(rule, li.deplibs)

        if def.version {
            cmd = shell()

            link = normpath("{dirname(lib)}/lib{def.name}{this.dlib_suffix}")

            add_rule({
                srcs: [lib]
                dsts: [link]
                cmd: cmd.symlink(libbase, link)
            })
        }

        if def.instdir != "none" {
            instlib = normpath("{get_instdir()}/{def.instdir}/{libbase}")

            add_install({
                src: lib
                dst: instlib
                mode: "0644"
                strip: true
            })

            if def.version {
                instlnk = normpath("{dirname(instlib)}/lib{def.name}{this.dlib_suffix}")

                add_install({
                    src: libbase
                    dst: instlnk
                    symlink: true
                })
            }
        }
    }
}