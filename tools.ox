ref "std/path"
ref "std/dir"
ref "std/io"
ref "std/lang"
ref "std/fs"
ref "json/json_schema"
ref "./config"
ref "./log"
ref "./inner_tools"
ref "./schema"
ref "./c_validator"
ref "./exe_validator"

/*?
 *? @lib Tool functions can be invoked in "lrbuild.ox"
 *?
 *? @otype{ ExeRule Executable program building rule.
 *? @var name {String} Name of the executable program.
 *? @var srcs {[String]} Source files of the executable program.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var pcs {[String]} Linked pkg-config modules.
 *? @var instdir {String} Installation directory.
 *? "none" means this program will not be installed.
 *? @otype}
 *?
 *? @otype{ LibRule Library building rule.
 *? @var name {String} Name of the executable program.
 *? @var srcs {[String]} Source files of the executable program.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var pcs {[String]} Linked pkg-config modules.
 *? @var instdir {String} Installation directory.
 *? "none" means this library will not be installed.
 *? @var exeinstdir {String} Executable program's installation directory.
 *? @var pic {Bool} Enable position indenpent code.
 *? @var version {String} The version number of the dynamic library.
 *? @otype}
 *?
 *? @otype{ GenRule Generator rule.
 *? @var srcs {[String]} Input files.
 *? @var name {String} Output file.
 *? @var cmd {String} Commands.
 *? @var instdir {String} Installation directory.
 *? @otype}
 *?
 *? @otype{ InstallRule Installation rule.
 *? @var srcs {[String]} source files.
 *? @var instdir {String} Installation directory.
 *? @otype}
 *?
 *? @otype{ Option Option.
 *? @var type {String} Type of the option.
 *? @var default The default value of the option.
 *? @var desc {String} The description of the option.
 *? @otype}
 *?
 *? @otype{ HDef Header file definition.
 *? @var name {String} The header filename.
 *? @var cflags {String} Compile flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var cxx {Bool} The file is a C++ header file.
 *? @otype}
 *?
 *? @otype{ LibDef Library definition.
 *? @var name {String} The library name.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var cxx {Bool} The file is a C++ library.
 *? @otype}
 *?
 *? @otype{ MacroDef Macro definition.
 *? @var name {String} The name of the macro.
 *? @var cflags {String} Compile flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var src {String} Source of the test code.
 *? @var cxx {Bool} The file is a C++ header file.
 *? @otype}
 *?
 *? @otype{ FuncDef Function definition.
 *? @var name {String} The name of the function.
 *? @var cflags {String} Compiler flags.
 *? @var ldflags {String} Linker flags.
 *? @var incdirs {[String]} Header file lookup directories.
 *? @var macros {[String]} Macro definitions.
 *? @var libdirs {[String]} Library lookup directories.
 *? @var libs {[String]} Linked libraries.
 *? @var src {String} The source of the test code.
 *? @var cxx {Bool} The file is a C++ library.
 *? @otype}
 *?
 *? @otype{ GtkDocRule Gtk document build rule.
 *? @var module {String} The module name.
 *? @var srcdir {String} Source directory.
 *? @var hdrs {[String]} Header files.
 *? @var formats {[String]} Document formats.
 *? @otype}
 *?
 *? @otype{ Package Package information.
 *? @var name {String} The package name.
 *? @var version {String} The version number.
 *? @otype}
 */

//Solve the pcs.
solve_pcs: func(def) {
    if def.pcs {
        pkgconfig = def.toolchain.pkgconfig

        for def.pcs as pc {
            mod = pkgconfig.module(pc)
            def.cflags += " {mod.cflags}"
            def.ldflags += " {mod.libs}"
        }
    }
}

//Set the production's properties
set_product: func(def) {
    def.srcs = def.srcs.$iter().map((get_full_path($))).to_array()
    def.toolchain = config.toolchain

    solve_pcs(def)
}

//Validate the input with the JSON schema
validate: func(def, sch, loc = def.location) {
    try {
        sch.validate_throw(def)
    } catch err {
        throw SyntaxError("{loc}: {err}")
    }
}

//Get the current location.
get_location: func() {
    stack = OX.stack()

    for stack as se {
        if se.filename ~ /lrbuild.ox$/i {
            return "\"{se.filename}\" {se.line}"
        }
    }
}

//Set the location to the definition.
set_location: func(def) {
    if def == null {
        throw NullError(L"{get_location()}: argument is null")
    }

    if def.location == null {
        def.location = get_location()
    }
}

/*?
 *? Add an executable program.
 *? @param def {ExeRule} Executable program building rule.
 */
public build_exe: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, exe_rule_schema)

    def.rule = "exe"

    if !def.instdir {
        def.instdir = "bin"
    }

    set_product(def)

    target = def.toolchain.target
    exe = "{def.name}{target.exe_suffix}"

    if def.instdir == "none" {
        instpath = "-{normpath("{config.currdir}/{exe}")}"
    } else {
        instpath = "+{normpath("{def.instdir}/{exe}")}"
    }

    config.add_product(instpath, def)
}

/*?
 *? Add a library.
 *? @param def {LibRule} Library building rule.
 */
public build_lib: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)

    sdef = {...def}

    sdef.pic = true

    build_slib(sdef)
    build_dlib(def)
}

/*?
 *? Add a static library.
 *? @param def {LibRule} Library building rule.
 */
public build_slib: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, lib_rule_schema)

    def.rule = "slib"

    if !def.instdir {
        def.instdir = "lib"
    }

    set_product(def)

    target = def.toolchain.target
    lib = "lib{def.name}{target.slib_suffix}"

    if def.instdir == "none" {
        instpath = "-{normpath("{config.currdir}/{lib}")}"
    } else {
        instpath = "+{normpath("{def.instdir}/{lib}")}"
    }

    def.libpath = instpath

    config.add_product(instpath, def)
}

/*?
 *? Add a dynamic library.
 *? @param def {LibRule} Library building rule.
 */
public build_dlib: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, lib_rule_schema)

    def.rule = "dlib"
    def.pic = true

    if !def.instdir {
        def.instdir = "lib"
    }

    if !def.exeinstdir {
        def.exeinstdir = "bin"
    }

    set_product(def)

    target = def.toolchain.target

    target.build_dlib(def)
}

/*?
 *? Generate a file.
 *? @param def {GenRule} Generator rule.
 */
public gen_file: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, gen_rule_schema)

    def.rule = "gen"

    if !def.instdir {
        def.instdir = "none"
    }

    set_product(def)

    if def.instdir == "none" {
        instpath = "-{normpath("{config.currdir}/{def.name}")}"
    } else {
        instpath = "+{normpath("{def.instdir}/{def.name}")}"
    }

    config.add_product(instpath, def)
}

/*?
 *? Install files.
 *? @param def {InstallRule} Installation rule.
 */
public install: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, install_rule_schema)

    def.rule = "install"

    set_product(def)

    if !def.mode {
        def.mode = "644"
    }

    config.add_install(def)
}

/*?
 *? Add subdirectories.
 *? @param dirs {[String]} The subdirectories.
 */
public subdirs: func(dirs) {
    validate(dirs, subdirs_schems, get_location())

    for dirs as dir {
        sub = "{config.currdir}/{dir}"

        run_lr_build(sub)
    }
}

/*?
 *? Set the toolchain used.
 *? @param tc {Toolchain} The toolchain.
 */
public toolchain: func(tc) {
    if config.job == Job.LISTOPT {
        return
    }

    if tc instof String {
        rtc = config.toolchains[tc]
        if !rtc {
            throw NullError(L"{get_location()}: illegal toolchain \"{tc}\"")
        }

        tc = rtc
    }
    config.toolchain = tc
}

/*?
 *? The options.
 */
public option: {}

//Check if 2 options' definitions are equal.
option_def_equal: func(o1, o2) {
    if o1.type instof String {
        if !(o2.type instof String) {
            return false
        }

        if o1.type != o2.type {
            return false
        }
    } else {
        if o1.type.length != o2.type.length {
            return false
        }

        for i = 0; i < o1.type.length; i += 1 {
            if o1.type[i] != o2.type[1] {
                return false
            }
        }
    }

    if o1.default != o2.default {
        return false
    }

    return true
}

//Get the option's value.
option_value: func(def, val) {
    case def.type {
    "boolean" {
        val = val.to_lower()
        if val == "1" || val == "true" || val == "yes" || val == "enabled" {
            val = true
        } elif val == "0" || val == "false" || val == "no" || val == "disabled" {
            val = false
        } else {
            return
        }
    }
    "number" {
        val = Number(val)
        if val.isnan() {
            return
        }
    }
    "integer" {
        val = Number(val)
        if val.isnan() {
            return null
        }

        if val.floor() != val {
            return null
        }
    }
    "string" {
    }
    (Array.is($)) {
        if !def.type.has(val) {
            return null
        }
    }
    }

    return val
}

/*?
 *? Add options.
 *? @param opts {[Option]} The options.
 */
public add_option: func(opts) {
    loc = get_location()

    validate(opts, options_schema, loc)

    for Object.entries(opts) as [name, def] {
        old = config.options[name]
        if old {
            if !option_def_equal(old, def) {
                throw ReferenceType(L"{loc}: option \"{name}\" is already declared")
            }
        }

        config.options[name] = def

        if config.job != Job.LISTOPT {
            val = config.settings[name]
            if val != null {
                val = option_value(def, val)
                if val == null {
                    throw RangeError(L"{loc}: \"{val}\" is not in option \"{name}\" valid values")
                }
            } else {
                val = def.default
            }

            option[name] = val
        }
    }
}

//Create a header validator.
h_validator: func(def) {
    validate(def, h_def_schema)

    if def instof String {
        name = def
        def = {
            name
        }
    }

    def.{
        toolchain: config.toolchain
        incdirs: config.incdirs
        macros: config.macros()
        cflags: config.cflags
    }

    solve_pcs(def)

    return HValidator(def)
}

/*?
 *? Check if the header file is valid.
 *? @param def {String|HDef} The header file definition.
 *? @return {Bool} The header exists or not.
 */
public have_h: func(def) {
    if config.job == Job.LISTOPT {
        return true
    }

    return h_validator(def).valid
}

/*?
 *? Assert the header file exists.
 *? @param def {String|HDef} The header file definition.
 */
public assert_h: func(def) {
    if config.job == Job.LISTOPT {
        return true
    }

    return h_validator(def).assert()
}

//Create a library validator.
lib_validator: func(def) {
    validate(def, lib_def_schema)

    if def instof String {
        name = def
        def = {
            name
            incdirs: config.incdirs
            macros: config.macros()
            libdirs: config.libdirs
            libs: config.libs
            cflags: config.cflags
            ldflags: config.ldflags
        }
    }

    def.toolchain = config.toolchain

    solve_pcs(def)

    return LibValidator(def)
}

/*?
 *? Check if the library is valid.
 *? @param def {String|LibDef} The library definition.
 *? @return {Bool} The library exists or not.
 */
public have_lib: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return lib_validator(def).valid
}

/*?
 *? Assert the library exist.
 *? @param def {String|LibDef} The library definition.
 */
public assert_lib: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return lib_validator(def).assert()
}

//Creata a macro validator.
macro_validator: func(def) {
    validate(def, macro_def_schema)

    if def instof String {
        name = def
        def = {
            name
            incdirs: config.incdirs
            macros: config.macros()
            cflags: config.cflags
        }
    }

    solve_pcs(def)

    def.toolchain = config.toolchain

    return MacroValidator(def)
}

/*?
 *? Check if the macro is defined.
 *? @param def {String|MacroDef} The macro definition.
 *? @return {Bool} The macro exists or not.
 */
public have_macro: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return macro_validator(def).valid
}

/*?
 *? Assert the macro is defined.
 *? @param def {String|MacroDef} The macro definition.
 */
public assert_macro: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return macro_validator(def).assert()
}

//Create a function validator.
func_validator: func(def) {
    validate(def, func_def_schema)

    if def instof String {
        name = def
        def = {
            name
            incdirs: config.incdirs
            macros: config.macros()
            libdirs: config.libdirs
            libs: config.libs
            cflags: config.cflags
            ldflags: config.ldflags
        }
    }

    solve_pcs(def)

    def.toolchain = config.toolchain

    return FuncValidator(def)
}

/*?
 *? Check if the function is defined.
 *? @param def {String|FuncDef} The function definition.
 *? @return {Bool} The function exists or not.
 */
public have_func: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return func_validator(def).valid
}

/*?
 *? Assert the function is defined.
 *? @param def {String|FuncDef} The function definition.
 */
public assert_func: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    return func_validator(def).assert()
}

/*?
 *? Get the "pkgconfig" module's cflags.
 *? @param mod {String} The module name.
 *? @return {String} The cflags.
 */
public pc_cflags: func(mod) {
    if config.job == Job.LISTOPT {
        return
    }

    tc = config.toolchain

    return tc.pkgconfig.module(mod).cflags
}

/*?
 *? Get the "pkgconfig" module's libs flags.
 *? @param mod {String} The module name.
 *? @return {String} The libs flags.
 */
public pc_libs: func(mod) {
    if config.job == Job.LISTOPT {
        return
    }

    tc = config.toolchain

    return tc.pkgconfig.module(mod).libs
}

/*?
 *? Check if the "pkgconfig" module is valid.
 *? @param mod {String} The module name.
 *? @return {Bool} The library exists or not.
 */
public have_pc: func(mod) {
    if config.job == Job.LISTOPT {
        return
    }

    tc = config.toolchain

    return tc.pkgconfig.module(mod).valid
}

/*?
 *? Assert the "pkgconfig" module is valid.
 *? @param mod {String} The module name.
 */
public assert_pc: func(mod) {
    if config.job == Job.LISTOPT {
        return
    }

    tc = config.toolchain

    return tc.pkgconfig.module(mod).assert()
}

/*?
 *? Check if the executable program is valid.
 *? @param exe {String} The program's name.
 *? @return {Bool} The program exists or not.
 */
public have_exe: func(exe) {
    if config.job == Job.LISTOPT {
        return
    }

    return ExeValidator(exe).valid
}

/*?
 *? Assert the executable program exists.
 *? @param exe {String} The program's name.
 */
public assert_exe: func(exe) {
    if config.job == Job.LISTOPT {
        return
    }

    return ExeValidator(exe).assert()
}

/*?
 *? Define a macro.
 *? @param name {String} Name of the macro.
 *? @param val {?String} Value of the macro.
 */
public define: func(name, val) {
    if config.job == Job.LISTOPT {
        return
    }

    config.macro_dict.add(name, val)
}

/*?
 *? Undefine a macro.
 *? @param name {String} Name of the macro.
 */
public undef: func(name) {
    if config.job == Job.LISTOPT {
        return
    }

    config.macro_dict.remove(name)
}

/*?
 *? Add a header lookup directory.
 *? @param dir {String} The directory.
 */
public add_incdir: func(dir) {
    if config.job == Job.LISTOPT {
        return
    }

    config.incdirs.add(get_full_path(dir))
}

/*?
 *? Add a library lookup directory.
 *? @param dir {String} The directory.
 */
public add_libdir: func(dir) {
    if config.job == Job.LISTOPT {
        return
    }

    config.libdirs.add(get_full_path(dir))
}

/*?
 *? Add a global linked library.
 *? @param lib {String} The library name.
 */
public add_lib: func(lib) {
    if config.job == Job.LISTOPT {
        return
    }

    config.libs.add(lib)
}

/*?
 *? Add compiler flags.
 *? @param f {String} The flags.
 */
public add_cflags: func(f) {
    if config.job == Job.LISTOPT {
        return
    }

    if config.cflags == null {
        config.cflags = f
    } else {
        config.cflags += " {f}"
    }
}

/*?
 *? Add linker flags.
 *? @param f {String} The flags.
 */
public add_ldflags: func(f) {
    if config.job == Job.LISTOPT {
        return
    }

    if config.ldflags == null {
        config.ldflags = f
    } else {
        config.ldflags += " {f}"
    }
}

/*?
 *? Save macros to a configuration header file.
 *? @param name {String} The name of the configuration header file.
 */
public config_h: func(name = "config.h") {
    if config.job == Job.LISTOPT {
        return
    }

    sb = String.Builder()
    for config.macro_dict.entries() as [mn, mv] {
        if mv == null {
            mv = "1"
        }

        sb.append("#define {mn} {mv}\n")
    }

    new = sb.$to_str()

    path = get_real_path(name)
    if Path(path).exist {
        old = File.load_text(path)
    }

    if new != old {
        mkdir_p(dirname(path))
        File.store_text(path, new)
        stdout.puts("store \"{path}\"\n")
    }

    config.configh.push(path)
}

/*?
 *? Configurate failed.
 *? @param msg {String} Message.
 *? 
 */
public failed: func(msg) {
    if config.job == Job.LISTOPT {
        return
    }

    loc = get_location()

    throw Error("{loc}: {msg}")
}

/*?
 *? Generate document throw gtkdoc.
 *? @param def {GtkDocRule} Rule to build gtk document.
 */
public gtkdoc: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    set_location(def)
    validate(def, gtkdoc_rule_schema)

    def.srcdir = get_full_path(def.srcdir)
    def.hdrs = def.hdrs.$iter().map((get_full_path($))).to_array()
    def.package = config.package

    config.add_gtkdoc(def)
}

/*?
 *? Set the package information.
 *? @param def {Package} The package information.
 */
public package: func(def) {
    if config.job == Job.LISTOPT {
        return
    }

    validate(def, package_schema)

    config.package = def
}