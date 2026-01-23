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
    dlib_suffix: ".dll"

    //Build dynamic library.
    build_dlib: func(def) {
        if def.version {
            dll = "lib{def.name}-{def.version}{this.dlib_suffix}"
        } else {
            dll = "lib{def.name}{this.dlib_suffix}"
        }

        if def.exeinstdir == "none" {
            instpath = "-{normpath("{config.currdir}/{dll}")}"
        } else {
            instpath = "+{normpath("{def.exeinstdir}/{dll}")}"
        }

        config.add_product(instpath, def)

        lib = "lib{def.name}{this.dlib_suffix}{this.slib_suffix}"

        if def.instdir == "none" {
            def.slib = "-{normpath("{config.currdir}/{lib}")}"
        } else {
            def.slib = "+{normpath("{def.instdir}/{lib}")}"
        }

        def.libpath = def.slib

        config.add_product(def.slib, {
            rule: "none"
            instdir: def.instdir
        })

        def.instdir = def.exeinstdir
    }
}