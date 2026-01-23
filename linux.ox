ref "std/path"
ref "./log"
ref "./config"

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
        if def.version {
            lib = "lib{def.name}{this.dlib_suffix}.{def.version}"
        } else {
            lib = "lib{def.name}{this.dlib_suffix}"
        }

        if def.instdir == "none" {
            instpath = "-{config.currdir}/{lib}"
            def.libpath = "-{normpath("{config.currdir}/lib{def.name}{this.dlib_suffix}")}"
        } else {
            instpath = "+{def.instdir}/{lib}"
            def.libpath = "+{normpath("{def.instdir}/lib{def.name}{this.dlib_suffix}")}"
        }

        config.add_product(instpath, def)

        if def.version {
            link = "lib{def.name}{this.dlib_suffix}"

            if def.instdir == "none" {
                linkpath = "-{normpath("{config.currdir}/{link}")}"
            } else {
                linkpath = "+{normpath("{def.instdir}/{link}")}"
            }

            config.add_product(linkpath, {
                rule: "symlink"
                instdir: def.instdir
                target: lib
                dep: instpath
            })
        }
    }
}