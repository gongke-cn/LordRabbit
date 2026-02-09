ref "std/path"
ref "json/json_schema"
ref "./basic"
ref "./log"

//JSON schem of GenRule
gen_rule_schema: JsonSchema({
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

/*?
 *? Generate a file.
 *? @param def {GenRule} Generator rule.
 */
public gen_file: func(def) {
    if !running() {
        return
    }

    try {
        gen_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    if !def.instdir {
        def.instdir = "none"
    }

    file = normpath("{get_outdir()}/{get_currdir()}/{def.name}")

    cmd = def.cmd.replace(/\$(@|<|^|[0-9]+|\$)/, func(m) {
        case m.$to_str() {
        "$@" {
            return file
        }
        "$<" {
            return get_path(def.srcs[0])
        }
        "$^" {
            return get_paths(def.srcs).$to_str(" ")
        }
        "$$" {
            return "$"
        }
        * {
            id = Number(m.slice(1))
            return get_path(def.srcs[id])
        }
        }
    })

    add_rule({
        srcs: get_paths(def.srcs)
        dsts: [file]
        cmd
    })

    if def.instdir != "none" {
        add_install({
            src: file
            dst: "{get_outdir()}/{def.instdir}/{def.name}"
            mode: "0644"
        })
    }
}
