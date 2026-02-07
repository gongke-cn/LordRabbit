ref "json/json_schema"

//JSON schema of ExeRule.
public exe_rule_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        srcs: {
            type: "array"
            minItems: 1
            items: {
                type: "string"
            }
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
        instdir: {
            type: "string"
        }
    }
    required: [
        "name"
        "srcs"
    ]
})

//JSON schema of LibRule.
public lib_rule_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        srcs: {
            type: "array"
            minItems: 1
            items: {
                type: "string"
            }
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
        instdir: {
            type: "string"
        }
        exeinstdir: {
            type: "string"
        }
        pic: {
            type: "boolean"
        }
    }
    required: [
        "name"
        "srcs"
    ]
})

//JSON schem of GenRule
public gen_rule_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        srcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
        cmd: {
            type: "string"
        }
    }
    required: [
        "name"
        "cmd"
    ]
})

//JSON schem of InstallRule.
public install_rule_schema: JsonSchema({
    type: "object"
    properties: {
        srcs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        srcdir: {
            type: "string"
        }
        instdir: {
            type: "string"
        }
    }
    required: [
        "instdir"
    ]
})

//JSON schema of Option array.
public options_schema: JsonSchema({
    type: "object"
    additionalProperties: {
        type: "object"
        properties: {
            type: {
                anyOf: [
                    {
                        type: "string"
                        "enum": [
                            "boolean"
                            "number"
                            "integer"
                            "string"
                        ]
                    }
                    {
                        type: "array"
                        itms: {
                            type: "string"
                        }
                    }
                ]
            }
            default: {
            }
            desc: {
                type: "string"
            }
        }
        required: [
            "type"
            "default"
            "desc"
        ]
    }
})

//JSON schema of sub directories.
public subdirs_schems: JsonSchema({
    type: "array"
    items: {
        type: "string"
    }
})

//JSON schema of header definition.
public h_def_schema: JsonSchema({
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
public lib_def_schema: JsonSchema({
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
public macro_def_schema: JsonSchema({
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
public func_def_schema: JsonSchema({
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

//JSON schema of gtk document rule.
public gtkdoc_rule_schema: JsonSchema({
    type: "object"
    properties: {
        module: {
            type: "string"
        }
        srcdir: {
            type: "string"
        }
        hdrs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        formats: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
    }
    required: [
        "module"
        "hdrs"
    ]
})

//JSON schema of package information.
public package_schema: JsonSchema({
    type: "object"
    properties: {
        name: {
            type: "string"
        }
        version: {
            type: "string"
        }
    }
    required: [
        "name"
        "version"
    ]
})