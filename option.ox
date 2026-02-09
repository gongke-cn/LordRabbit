ref "json/json_schema"
ref "./basic"
ref "./config"
ref "./log"

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

//JSON schema of Option array.
options_schema: JsonSchema({
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

/*?
 *? Add options.
 *? @param opts {[Option]} The options.
 */
public add_option: func(opts) {
    loc = get_location()

    try {
        options_schema.validate_throw(opts)
    } catch e {
        throw Error("{loc}: {e}")
    }

    for Object.entries(opts) as [name, def] {
        old = config.options[name]
        if old {
            if !option_def_equal(old, def) {
                throw ReferenceType(L"{loc}: option \"{name}\" is already declared")
            }
        }

        config.options[name] = def

        if running() {
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
