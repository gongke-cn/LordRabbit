ref "std/shell"
ref "./log"
ref "./tools"
ref "./validator"
ref "./exe_validator"
ref "./output_validator"

//Wrapper of "pkg-config".
public PkgConfig: class ExeValidator {
    //Initialize the "pkg-config" program name.
    $init(name) {
        ExeValidator.$inf.$init.call(this, name)

        this.modules = {}
    }

    //Get a module.
    module(name) {
        m = name.match(/(.+):(.+)/p)
        if m {
            name = m.groups[1]
            version = m.groups[2]
        }

        old = this.modules[name]
        if old {
            return old
        }

        mod = PkgConfigValidator(this, name, version)
        this.modules[name] = mod

        return mod
    }
}

//Validator the library module by "pkg-config"
PkgConfigValidator: class Validator {
    //Initialize.
    $init(pkgconfig, module, version) {
        this.{
            pkgconfig
            module
            min_version: version
            #exists: OutputValidator("{pkgconfig} {module} --exists")
            #version: OutputValidator("{pkgconfig} {module} --modversion")
            #cflags: OutputValidator("{pkgconfig} {module} --cflags")
            #libs: OutputValidator("{pkgconfig} {module} --libs")
        }
    }

    //Check the module.
    check() {
        this.pkgconfig.assert()

        if !this.#exists.valid {
            return null
        }

        desc = this.module

        if this.min_version {
            this.#version.assert()
            version = this.#version.value

            curr = (version ~ /\d+(\.\d+)*/).split(".").to_array()
            min = (this.min_version ~ /\d+(\.\d+)*/).split(".").to_array()

            for i = 0; ; i += 1 {
                if i == curr.length && i == min.length {
                    break
                } elif i == curr.length {
                    return null
                } elif i == min.length {
                    break
                } else {
                    cn = Number(curr[i])
                    mn = Number(min[i])

                    if cn < mn {
                        return null
                    } elif cn > mn {
                        break
                    }
                }
            }

            desc += ":{version}"
        }

        return desc
    }

    //To string.
    $to_str() {
        desc = this.module

        if this.min_version {
            desc += ":{this.min_version}"
        }

        return desc
    }

    //Get the C flags.
    cflags {
        this.assert()
        this.#cflags.assert()

        return this.#cflags.value
    }

    //Get the linker flags.
    libs {
        this.assert()
        this.#libs.assert()

        return this.#libs.value
    }

    //Get the tag.
    tag {
        return "{Object.get_name(this.$class)}:{this.module}"
    }
}
