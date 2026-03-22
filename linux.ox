ref "std/path"
ref "json/json"
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
    build_dlib: func(def) {
        lib = def.target
        libbase = basename(def.target)
    
        if def.version {
            lib = "{lib}.{def.version}"
            libbase = "{libbase}.{def.version}"
        }

        tc = def.toolchain
        cmd = shell()

        pcs = [...get_pcs(), ...def.pcs]
        pc_libs = pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
        ldflags = "{def.ldflags} {pc_libs} {get_ldflags()}"
        libdirs = [...def.libdirs, ...get_libdirs()]
        libs = [...def.libs, ...get_libs()]

        linkcmd = tc.objs2dlib({
            objs: def.objs
            lib
            libdirs
            libs
            ldflags
            cxx: def.cxx
        })

        rule = {
            srcs: def.srcs
            dsts: [lib]
            cmd: ''
{{cmd.mkdir(dirname(lib))}}
{{linkcmd}}
            ''
        }

        add_rule(rule)

        if def.version {
            link = def.target

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

        add_product(lib)
    }
}
