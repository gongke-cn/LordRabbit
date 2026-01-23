ref "std/system"
ref "std/lang"
ref "std/path"
ref "./log"
ref "./validator"

//Validator of an executable program.
public ExeValidator: class Validator {
    //Initialize an executable program validator.
    $init(exe) {
        this.exe = exe
    }

    //Convert to string.
    $to_str() {
        return this.exe
    }

    //Check if the executable program exists.
    check() {
        pl = getenv("PATH")
        if !pl {
            return
        }

        if OX.os == "windows" {
            sep = ";"
        } else {
            sep = ":"
        }

        for pl.split(sep) as dn {
            path = "{dn.trim()}/{this.exe}"
            
            if Path(path).exist {
                return path
            }

            if OX.os == "windows" {
                fn = "{path}.exe"
                if Path(fn).exist {
                    return fn
                }

                fn = "{path}.com"
                if Path(fn).exist {
                    return fn
                }

                fn = "{path}.bat"
                if Path(fn).exist {
                    return fn
                }
            }
        }
    }
}