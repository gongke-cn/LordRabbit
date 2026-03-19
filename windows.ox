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
    build_dlib: func(def) {
        lib = def.target

        if def.version {
            dllbase = "lib{def.name}-{def.version}.dll"
        } else {
            dllbase = "lib{def.name}.dll"
        }

        dll = "{dirname(lib)}/{dllbase}"

        tc = def.toolchain

        pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
        ldflags = "{def.ldflags} {pc_libs} {get_ldflags()}"
        libdirs = [...def.libdirs, ...get_libdirs()]
        libs = [...def.libs, ...get_libs()]

        linkcmd = tc.objs2dlib({
            objs: def.objs
            lib: dll
            slib: lib
            libdirs
            libs
            ldflags
            cxx: def.cxx
        })

        cmd = shell()

        rule = {
            srcs: def.srcs
            dsts: [dll, lib]
            cmd: ''
{{cmd.mkdir(dirname(dll))}}
{{cmd.mkdir(dirname(lib))}}
{{linkcmd}}
            ''
        }

        add_rule(rule)

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
                dst: normpath("{get_instdir()}/{def.exeinstdir}/{dllbase}")
                mode: "0644"
                strip: true
            })
        }

        add_product(lib)
        add_product(dll)
    }
}