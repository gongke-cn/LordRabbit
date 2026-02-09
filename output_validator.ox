ref "std/shell"
ref "std/process"
ref "./validator"
ref "./log"

//Program's output validator.
public OutputValidator: class Validator {
    //Initialize.
    $init(cmd) {
        this.#cmd = cmd
    }

    //Check.
    check() {
        p = Shell(this.#cmd, Process.STDOUT|Process.NULLIN|Process.NULLERR)
        sb = String.Builder()

        while true {
            line = p.stdout.gets()
            if line == null {
                break
            }

            sb.append(line)
        }

        if p.wait() != 0 {
            return null
        }

        return sb.$to_str().trim()
    }

    //To string.
    $to_str() {
        return this.value
    }

    //Get the tag.
    tag {
        return "{Object.get_name(this.$class)}:{this.#cmd}"
    }

    //Get the description.
    desc {
        return this.#cmd
    }
}