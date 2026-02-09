ref "json/json_schema"
ref "./c_validator"
ref "./basic"
ref "./log"

//JSON schema of header definition.
h_def_schema: JsonSchema({
    anyOf: [
        {
            type: "string"
        }
        {
            type: "object"
            properties: {
                name: {
                    type: "string"
                }
                cflags: {
                    type: "string"
                }
                incdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                incs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                macros: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                pcs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                cxx: {
                    type: "boolean"
                }
            }
            required: [
                "name"
            ]
        }
    ]
})

//JSON schema of library definition.
lib_def_schema: JsonSchema({
    anyOf: [
        {
            type: "string"
        }
        {
            type: "object"
            properties: {
                name: {
                    type: "string"
                }
                cflags: {
                    type: "string"
                }
                ldflags: {
                    type: "string"
                }
                incdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                incs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                macros: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                libdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                libs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                pcs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                cxx: {
                    type: "boolean"
                }
            }
            required: [
                "name"
            ]
        }
    ]
})

//JSON schema of macro definition.
macro_def_schema: JsonSchema({
    anyOf: [
        {
            type: "string"
        }
        {
            type: "object"
            properties: {
                name: {
                    type: "string"
                }
                cflags: {
                    type: "string"
                }
                incdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                incs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                macros: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                pcs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                cxx: {
                    type: "boolean"
                }
                src: {
                    type: "string"
                }
            }
            required: [
                "name"
            ]
        }
    ]
})

//JSON schema of funciton definition.
func_def_schema: JsonSchema({
    anyOf: [
        {
            type: "string"
        }
        {
            type: "object"
            properties: {
                name: {
                    type: "string"
                }
                cflags: {
                    type: "string"
                }
                ldflags: {
                    type: "string"
                }
                incdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                incs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                macros: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                libdirs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                libs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                pcs: {
                    type: "array"
                    items: {
                        type: "string"
                    }
                }
                cxx: {
                    type: "boolean"
                }
                src: {
                    type: "string"
                }
            }
            required: [
                "name"
            ]
        }
    ]
})

//Create a header validator.
h_validator: func(def) {
    try {
        h_def_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if def instof String {
        def = {
            name: def
        }
    }

    tc = toolchain()

    if def.pcs {
        pc_cflags = def.pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")
    }

    def.{
        toolchain: tc
        incdirs: [...def.incdirs, ...get_incdirs()]
        incs: [...def.incs, ...get_incs()]
        macros: [...def.macros, ...get_macros()]
        cflags: "{def.cflags} {pc_cflags} {get_cflags()}"
    }

    return HValidator(def)
}

/*?
 *? Check if the header file is valid.
 *? @param def {String|HDef} The header file definition.
 *? @return {Bool} The header exists or not.
 */
public have_h: func(def) {
    if !running() {
        return true
    }

    return h_validator(def).valid
}

/*?
 *? Assert the header file exists.
 *? @param def {String|HDef} The header file definition.
 */
public assert_h: func(def) {
    if !running() {
        return true
    }

    return h_validator(def).assert()
}

//Create a library validator.
lib_validator: func(def) {
    try {
        lib_def_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if def instof String {
        name = def
        def = {
            name: def
        }
    }

    tc = toolchain()

    if def.pcs {
        pc_cflags = def.pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")
        pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
    }

    def.{
        toolchain: tc
        incdirs: [...def.incdirs, ...get_incdirs()]
        incs: [...def.incs, ...get_incs()]
        macros: [...def.macros, ...get_macros()]
        libdirs: [...def.libdirs, ...get_libdirs()]
        libs: [...def.libs, ...get_libs()]
        cflags: "{def.cflags} {pc_cflags} {get_cflags()}"
        ldflags: "{def.ldflags} {pc_libs} {get_ldflags()}"
    }

    return LibValidator(def)
}

/*?
 *? Check if the library is valid.
 *? @param def {String|LibDef} The library definition.
 *? @return {Bool} The library exists or not.
 */
public have_lib: func(def) {
    if !running() {
        return
    }

    return lib_validator(def).valid
}

/*?
 *? Assert the library exist.
 *? @param def {String|LibDef} The library definition.
 */
public assert_lib: func(def) {
    if !running() {
        return
    }

    return lib_validator(def).assert()
}

//Creata a macro validator.
macro_validator: func(def) {
    try {
        macro_def_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if def instof String {
        def = {
            name: def
        }
    }

    tc = toolchain()
    if def.pcs {
        pc_cflags = def.pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")
    }

    def.{
        toolchain: tc
        incdirs: [...def.incdirs, ...get_incdirs()]
        incs: [...def.incs, ...get_incs()]
        macros: [...def.macros, ...get_macros()]
        cflags: "{def.cflags} {pc_cflags} {get_cflags()}"
    }

    return MacroValidator(def)
}

/*?
 *? Check if the macro is defined.
 *? @param def {String|MacroDef} The macro definition.
 *? @return {Bool} The macro exists or not.
 */
public have_macro: func(def) {
    if !running() {
        return
    }

    return macro_validator(def).valid
}

/*?
 *? Assert the macro is defined.
 *? @param def {String|MacroDef} The macro definition.
 */
public assert_macro: func(def) {
    if !running() {
        return
    }

    return macro_validator(def).assert()
}

//Create a function validator.
func_validator: func(def) {
    try {
        func_def_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if def instof String {
        def = {
            name: def
        }
    }

    tc = toolchain()

    if def.pcs {
        pc_cflags = def.pcs.$iter().map((tc.pkgconfig.module($).cflags)).$to_str(" ")
        pc_libs = def.pcs.$iter().map((tc.pkgconfig.module($).libs)).$to_str(" ")
    }

    def.{
        toolchain: tc
        incdirs: [...def.incdirs, ...get_incdirs()]
        incs: [...def.incs, ...get_incs()]
        macros: [...def.macros, ...get_macros()]
        libdirs: [...def.libdirs, ...get_libdirs()]
        libs: [...def.libs, ...get_libs()]
        cflags: "{def.cflags} {pc_cflags} {get_cflags()}"
        ldflags: "{def.ldflags} {pc_libs} {get_ldflags()}"
    }

    return FuncValidator(def)
}

/*?
 *? Check if the function is defined.
 *? @param def {String|FuncDef} The function definition.
 *? @return {Bool} The function exists or not.
 */
public have_func: func(def) {
    if !running() {
        return
    }

    return func_validator(def).valid
}

/*?
 *? Assert the function is defined.
 *? @param def {String|FuncDef} The function definition.
 */
public assert_func: func(def) {
    if !running() {
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
    if !running() {
        return
    }

    tc = toolchain()

    return tc.pkgconfig.module(mod).cflags
}

/*?
 *? Get the "pkgconfig" module's libs flags.
 *? @param mod {String} The module name.
 *? @return {String} The libs flags.
 */
public pc_libs: func(mod) {
    if !running() {
        return
    }

    tc = toolchain()

    return tc.pkgconfig.module(mod).libs
}

/*?
 *? Check if the "pkgconfig" module is valid.
 *? @param mod {String} The module name.
 *? @return {Bool} The library exists or not.
 */
public have_pc: func(mod) {
    if !running() {
        return
    }

    tc = toolchain()

    return tc.pkgconfig.module(mod).valid
}

/*?
 *? Assert the "pkgconfig" module is valid.
 *? @param mod {String} The module name.
 */
public assert_pc: func(mod) {
    if !running() {
        return
    }

    tc = toolchain()

    return tc.pkgconfig.module(mod).assert()
}

/*?
 *? Check if the executable program is valid.
 *? @param exe {String} The program's name.
 *? @return {Bool} The program exists or not.
 */
public have_exe: func(exe) {
    if !running() {
        return
    }

    return ExeValidator(exe).valid
}

/*?
 *? Assert the executable program exists.
 *? @param exe {String} The program's name.
 */
public assert_exe: func(exe) {
    if !running() {
        return
    }

    return ExeValidator(exe).assert()
}
