
ref "std/io"
ref "std/path"
ref "std/fs"
ref "./exe_validator"
ref "./inner_tools"
ref "./tools"
ref "./shell_command"
ref "./config"
ref "./log"

//Makefile.
Makefile: class ExeValidator {
    //Initialize.
    $init() {
        ExeValidator.$inf.$init.call(this, "make")
    }

    //Prepare.
    prepare() {
        this.instdir = config.instdir

        config.shell = ShellCommand()

        if !config.outfile {
            config.outfile = "Makefile"
        }
    }

    //Generate the "Makefile".
    generate() {
        this.assert()

        this.{
            phony: "all clean cleanout install uninstall"
            rules: ""
            deps: ""
            clean: ""
            cleandir: ""
        }

        tab = "\t"
        cmd = shell()

        make_cmd: func(src) {
            return src.split("\n").map(("\t$(Q){$.replace("$", "$$$$")}")).$to_str("\n")
        }

        for config.rules as rule {
            targets = null
            srcs = null

            clean: func(fn) {
                if fn.slice(-1) == "/" {
                    this.cleandir += " {fn}"
                } else {
                    this.clean += " {fn}"
                }
            }

            for rule.dsts as fn {
                clean(fn)
            }

            if rule.phony {
                this.phony += " {rule.phony}"
                targets = rule.phony
            } else {
                for rule.dsts as fn {
                    if fn ~ /\.dep$/ {
                        this.deps += " {fn}"
                    } elif fn ~ /\.o$/ {
                        targets += " {fn}"
                    } else {
                        targets += " {fn}"
                    }
                }

                targets = targets.trim()
            }

            if rule.srcs {
                srcs = rule.srcs.$iter().$to_str(" ")
            }

            this.rules += ''
{{targets}}: {{srcs}}
{{tab}}$(info BUILD {{targets}} <= {{srcs}})
{{make_cmd(rule.cmd)}}


            ''
        }

        clean_cmd = null

        if this.clean {
            clean_cmd = make_cmd(cmd.rm(this.clean))
        }

        if this.cleandir {
            if clean_cmd {
                clean_cmd += "\n"
            }
            clean_cmd += make_cmd(cmd.rmdir(this.cleandir))
        }

        File.store_text(config.outfile, ''
Q ?= @

all: {{config.products.$to_str(" ")}}

{{config.outfile}}: {{config.buildfiles.$to_str(" ")}}
{{tab}}$(info CONFIG $@)
{{make_cmd(config.cli_args.$iter().map(("\"{$}\"")).$to_str(" "))}}

-include {{this.deps}}

{{this.rules}}

install: all uninstall
{{tab}}$(info INSTALL)
{{make_cmd(config.install)}}

uninstall:
{{tab}}$(info UNINSTALL)
{{make_cmd(config.uninstall)}}

clean:
{{tab}}$(info CLEAN)
{{clean_cmd}}

cleanout:
{{tab}}$(info CLEAN OUTPUT)
{{make_cmd(cmd.rmdir(config.outdir))}}

.PHONY: {{this.phony}}

        '')
    }
}

//Add makefile
register_generator(Makefile(), "make")