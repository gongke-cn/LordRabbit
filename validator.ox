ref "std/io"
ref "./config"
ref "./log"

//Validator.
public Validator: class {
    //Get the valid flag.
    valid {
        if this.#tested == null {
            this.#value = config.cache[this.tag]

            if this.#value == null {
                this.#value = this.check()
                config.cache[this.tag] = this.#value

                stdout.puts(L"check \"{this.desc}\": ")
                if this.#value != null {
                    result = this.#value
                    if result == "" {
                        result = "ok"
                    }
                    stdout.puts("{result}\n")
                } else {
                    stdout.puts(L"failed\n")
                }
            }

            this.#tested = true
        }

        return this.#value != null
    }

    //Assert the validator is valid.
    assert() {
        if !this.valid {
            throw NullError(L"\"{this}\" is not valid")
        }

        return this.#value
    }

    //Get the value.
    value {
        this.assert()

        return this.#value
    }

    //Get the tag.
    tag {
        return "{Object.get_name(this.$class)}:{this}"
    }

    //Get the description of the tag.
    desc {
        return this.$to_str()
    }
}