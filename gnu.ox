ref "std/shell"
ref "std/path"
ref "./config"
ref "./inner_tools"
ref "./tools"
ref "./log"
ref "./windows"
ref "./linux"
ref "./pkgconfig"
ref "./exe_validator"
ref "./shell_command"

/*?
 *? @otype{ C2ObjRule Rule of compiling C to object.
 *? @var src {String} The source C file.
 *? @var obj {String} The object file.
 *? @var dep {String} The dependency file.
 *? @var cflags {String} The compile flags.
 *? @var incdirs {[String]} The include directories.
 *? @var incs {[String]} Include header files.
 *? @var macros {[String]} The macro definitions.
 *? @var pic {Bool} Enable PIC flag.
 *? @otype}
 *?
 *? @otype{ Objs2ExeRule Rule of linking objects to executable program.
 *? @var objs {[String]} The object files.
 *? @var exe {String} The target executable program.
 *? @var ldflags {String} The linker flags.
 *? @var libdirs {[String]} The library lookup directories.
 *? @var libs {[String]} the linked libraries.
 *? @otype}
 *?
 *? @otype{ Objs2LibRule Rule of linking objects to static library.
 *? @var objs {[String]} The object files.
 *? @var lib {String} The target library.
 *? @var ldflags {String} The linker flags.
 *? @var libdirs {[String]} The library lookup directories.
 *? @var libs {[String]} The linked libraries.
 *? @var slib {String} The ".dll.a" filename.
 *? @otype}
 */

//? GNU toolchain.
public GnuToolchain: class {
    /*?
     *? Initialize the GNU toolchain.
     *? @param xprefix {String} The cross compile toolchain's prefix.
     */
    $init(xprefix) {
        this.{
            xprefix
            cc: ExeValidator("{this.xprefix}gcc")
            cxx: ExeValidator("{this.xprefix}g++")
            ar: ExeValidator("{this.xprefix}ar")
            ranlib: ExeValidator("{this.xprefix}ranlib")
        }
    }

    //Assert the C compiler.
    cc_assert() {
        if !this.cc.valid {
            if !this.cxx.valid {
                throw NullError("\"{this.cc}\" is not valid")
            } else {
                this.cc = this.cxx
            }
        }
    }

    //Get the target.
    target {
        if this.#target == null {
            this.cc_assert()

            out = Shell.error("{this.cc} -v")

            for out.split("\n") as line {
                m = line.match(/Target:\s*(.+)/)
                if m {
                    tn = m.groups[1]
                    break
                }
            }

            if !tn {
                throw NullError(L"cannot get target information from \"{this.cc}\"")
            }

            if tn ~ /\b(windows|mingw32)\b/ {
                this.#target = Windows
            } else {
                this.#target = Linux
            }
        }

        return this.#target
    }

    //Get the pkgconfig.
    pkgconfig {
        if this.#pkgconfig == null {
            this.#pkgconfig = PkgConfig("{this.xprefix}pkg-config")
        }

        return this.#pkgconfig
    }

    /*?
     *? Get the C compiling command line.
     *? @param def {C2ObjRule} C compiling rule.
     *? @return {String} The command line.
     */
    c2obj(def) {
        this.cc_assert()

        if def.dep {
            depflags = "-MMD -MF {def.dep}"
        }

        if def.pic {
            picflags = "-fPIC"
        }

        if def.incdirs {
            incdirs = def.incdirs.$iter().map(("-I{$}")).$to_str(" ")
        }

        if def.macros {
            macros = def.macros.$iter().map(("-D{$}")).$to_str(" ")
        }

        if def.incs {
            incs = def.incs.$iter().map(("-include {$}")).$to_str(" ")
        }

        if config.debug {
            gflag = "-g"
        }

        return "{this.cc} -c -o {def.obj} {def.src} {depflags} {picflags} {macros} {incdirs} {incs} {def.cflags} {gflag}"
    }

    /*?
     *? Get the C++ compiling command line.
     *? @param def {C2ObjRule} C++ compiling rule.
     *? @return {String} The command line.
     */
    cxx2obj(def) {
        this.cxx.assert()

        if def.dep {
            depflags = "-MMD -MF {def.dep}"
        }

        if def.pic {
            picflags = "-fPIC"
        }

        if def.incdirs {
            incdirs = def.incdirs.$iter().map(("-I{$}")).$to_str(" ")
        }

        if def.macros {
            macros = def.macros.$iter().map(("-D{$}")).$to_str(" ")
        }

        if config.debug {
            gflag = "-g"
        }

        return "{this.cxx} -c -o {def.obj} {def.src} {depflags} {picflags} {macros} {incdirs} {def.cflags} {gflag}"
    }

    /*?
     *? Get the executable program generator command line.
     *? @param def {Objs2ExeRule} Executable program generator rule.
     *? @return {String} The command line.
     */
    objs2exe(def) {
        if def.cxx {
            this.cxx.assert()
            cc = this.cxx
        } else {
            this.cc_assert()
            cc = this.cc
        }

        if def.libdirs {
            libdirs = def.libdirs.$iter().map(("-L{$}")).$to_str(" ")
        }

        if def.libs {
            libs = def.libs.$iter().map(("-l{$}")).$to_str(" ")
        }

        return "{cc} -o {def.exe} {def.objs.$to_str(" ")} {libdirs} {libs} {def.ldflags}"
    }

    /*?
     *? Get the static library generator command line.
     *? @param def {Objs2LibRule} Static library generator rule.
     *? @return {String} The command line.
     */
    objs2slib(def) {
        this.ar.assert()
        this.ranlib.assert()

        return ''
{{this.ar}} rcs {{def.lib}} {{def.objs.$to_str(" ")}}
{{this.ranlib}} {{def.lib}}
        ''
    }

    /*?
     *? Get the dynamic library generator command line.
     *? @param def {Objs2LibRule} Dynamic library generator rule.
     *? @return {String} The command line.
     */
    objs2dlib(def) {
        if def.cxx {
            this.cxx.assert()
            cc = this.cxx
        } else {
            this.cc_assert()
            cc = this.cc
        }

        target = this.target

        if def.libdirs {
            libdirs = def.libdirs.$iter().map(("-L{$}")).$to_str(" ")
        }

        if def.libs {
            libs = def.libs.$iter().map(("-l{$}")).$to_str(" ")
        }

        base = basename(def.lib)

        if target.name == "linux" {
            if base ~ /lib(.+)\.so\.(.+)/p {
                flags = "-Wl,-soname,{base}"
            }
        } elif target.name == "windows" {
            flags = "-Wl,--out-implib,{def.slib}"
        }

        return "{cc} -o {def.lib} {def.objs.$to_str(" ")} -shared {libdirs} {libs} {def.ldflags} {flags}"
    }
}

//Add GNU toolchain
register_toolchain(GnuToolchain(), "gnu")

//Add GNU toolchain with clang
tc = GnuToolchain()
tc.cc = ExeValidator("{tc.xprefix}clang")
tc.cxx = ExeValidator("{tc.xprefix}clang++")
register_toolchain(tc, "gnu-clang")