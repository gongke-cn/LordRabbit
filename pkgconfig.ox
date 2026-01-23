ref "std/shell"
ref "./log"
ref "./tools"
ref "./validator"
ref "./exe_validator"

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
        }
    }

    //Check the module.
    check() {
        this.pkgconfig.assert()

        cmd = "{this.pkgconfig} --exists {this.module}"
        r = Shell.run(cmd)
        if r != 0 {
            return null
        }

        desc = this.module

        if this.min_version {
            cmd = "{this.pkgconfig} {this.module} --modversion"
            version = Shell.output(cmd).trim()

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

    //Get the version number.
    version {
        if this.#version == null {
            this.assert()

            cmd = "{this.pkgconfig} {this.module} --modversion"

            this.#version = Shell.output(cmd).trim()
        }

        return this.#version
    }

    //Get the C flags.
    cflags {
        if this.#cflags == null {
            this.assert()

            cmd = "{this.pkgconfig} {this.module} --cflags"

            this.#cflags = Shell.output(cmd).trim()
        }

        return this.#cflags
    }

    //Get the linker flags.
    libs {
        if this.#libs == null {
            this.assert()

            cmd = "{this.pkgconfig} {this.module} --libs"

            this.#libs = Shell.output(cmd).trim()
        }

        return this.#libs
    }

    //Get the tag.
    tag {
        return "{Object.get_name(this.$class)}:{this.module}"
    }
}
