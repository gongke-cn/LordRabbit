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
            }

            stdout.puts(L"check \"{this}\": ")
            if this.#value != null {
                stdout.puts("{this.#value}\n")
            } else {
                stdout.puts(L"failed\n")
            }

            this.#tested = true
        }

        return this.#value
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
}