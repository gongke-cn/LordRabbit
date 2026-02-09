ref "std/shell"
ref "std/temp_file"
ref "std/io"
ref "std/fs"
ref "std/path"
ref "./validator"
ref "./config"
ref "./log"

//C compile validator.
public CCValidator: class Validator {
    //Initialize.
    $init(def) {
        this.{
            name: def.name
            toolchain: def.toolchain
            cxx: def.cxx
            src: def.src
            cflags: def.cflags
            incdirs: def.incdirs
            macros: def.macros
        }
    }

    //Check the result.
    check() {
        target = this.toolchain.target
        #src_file = TempFile("{config.outdir}/c_validator/lrtest.c")
        #obj_file = TempFile("{config.outdir}/c_validator/lrtest.o")

        mkdir_p(dirname(src_file))
        File.store_text(src_file, this.src)

        rule = {
            src: src_file
            obj: obj_file
            cflags: this.cflags
            incdirs: this.incdirs
            macros: this.macros
        }

        if !this.cxx {
            cmd = this.toolchain.c2obj(rule)
        } else {
            cmd = this.toolchain.cxx2obj(rule)
        }

        if Shell.run(cmd, Shell.ERROR) != 0 {
            return
        }

        return this.$to_str()
    }

    //To string.
    $to_str() {
        return this.name
    }
}

//C linker validator.
public CLinkValidator: class Validator {
    //Initialize.
    $init(def) {
        this.{
            name: def.name
            toolchain: def.toolchain
            cxx: def.cxx
            src: def.src
            cflags: def.cflags
            ldflags: def.ldflags
            incdirs: def.incdirs
            macros: def.macros
            libdirs: def.libdirs
            libs: def.libs
        }
    }

    //Check the result.
    check() {
        target = this.toolchain.target
        #src_file = TempFile("{config.outdir}/c_validator/lrest.c")
        #obj_file = TempFile("{config.outdir}/c_validator/lrtest.o")
        #exe_file = TempFile("{config.outdir}/c_validator/lrtest{target.exe_suffix}")

        mkdir_p(dirname(src_file))
        File.store_text(src_file, this.src)

        rule = {
            src: src_file
            obj: obj_file
            cflags: this.cflags
            incdirs: this.incdirs
            macros: this.macros
        }

        if !this.cxx {
            cmd = this.toolchain.c2obj(rule)
        } else {
            cmd = this.toolchain.cxx2obj(rule)
        }

        if Shell.run(cmd, Shell.ERROR) != 0 {
            return
        }

        cmd = this.toolchain.objs2exe({
            objs: [
                obj_file
            ]
            exe: exe_file
            ldflags: this.ldflags
            libdirs: this.libdirs
            libs: this.libs
        })

        if Shell.run(cmd, Shell.ERROR) != 0 {
            return
        }

        return this.$to_str()
    }

    //To string.
    $to_str() {
        return this.name
    }
}

//Header file validator.
public HValidator: class CCValidator {
    $init(def) {
        CCValidator.$inf.$init.call(this, {
            name: def.name
            toolchain: def.toolchain
            cflags: def.cflags
            incdirs: def.incdirs
            macros: def.macros
            cxx: def.cxx
            src: ''
#include <{{def.name}}>

            ''
        })
    }
}

//Library validator.
public LibValidator: class CLinkValidator {
    $init(def) {
        libs = [def.name]

        if def.libs {
            libs.[...def.libs]
        }

        CLinkValidator.$inf.$init.call(this, {
            name: "lib{def.name}"
            toolchain: def.toolchain
            cflags: def.cflags
            ldflags: def.ldflags
            incdirs: def.incdirs
            macros: def.macros
            libdirs: def.libdirs
            libs: libs
            cxx: def.cxx
            src: ''
int main (int argc, char **argv) {
    return 0;
}
            ''
        })
    }
}

//Macro validator.
public MacroValidator: class CCValidator {
    $init(def) {
        CCValidator.$inf.$init.call(this, {
            name: def.name
            toolchain: def.toolchain
            cflags: def.cflags
            incdirs: def.incdirs
            macros: def.macros
            cxx: def.cxx
            src: ''
{{def.src}}
#ifndef {{def.name}}
    #error {{def.name}} is not defined!
#endif
            ''
        })
    }
}

//Function validator.
public FuncValidator: class CLinkValidator {
    $init(def) {
        if def.src {
            src = def.src
        } else {
            src =  ''
#include <stdio.h>

int main (int argc, char **argv) {
    printf("%p\n", {{def.name}});
    return 0;
}
            ''
        }

        CLinkValidator.$inf.$init.call(this, {
            name: def.name
            toolchain: def.toolchain
            cflags: def.cflags
            ldflags: def.ldflags
            incdirs: def.incdirs
            macros: def.macros
            libdirs: def.libdirs
            libs: def.libs
            cxx: def.cxx
            src
        })
    }
}