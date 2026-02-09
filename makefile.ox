
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

        config.instdir = "$(INST)"
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
{{rule.cmd.split("\n").map(("\t$(Q){$}")).$to_str("\n")}}


            ''
        }

        clean_cmd = null

        if this.clean {
            clean_cmd = "\t$(Q){cmd.rm(this.clean)}"
        }

        if this.cleandir {
            if clean_cmd {
                clean_cmd += "\n"
            }
            clean_cmd += "\t$(Q){cmd.rmdir(this.cleandir)}"
        }

        File.store_text(config.outfile, ''
Q ?= @
INST ?= {{this.instdir}}

all: {{config.products.$to_str(" ")}}

{{config.outfile}}: {{config.buildfiles.$to_str(" ")}}
{{tab}}$(info CONFIG $@)
{{tab}}$(Q){{config.cli_args.$iter().map(("\"{$}\"")).$to_str(" ")}}

-include {{this.deps}}

{{this.rules}}

install: all uninstall
{{tab}}$(info INSTALL)
{{config.install.split("\n").map(("\t$(Q){$}")).$to_str("\n")}}

uninstall:
{{tab}}$(info UNINSTALL)
{{config.uninstall.split("\n").map(("\t$(Q){$}")).$to_str("\n")}}

clean:
{{tab}}$(info CLEAN)
{{clean_cmd}}

cleanout:
{{tab}}$(info CLEAN OUTPUT)
{{tab}}$(Q){{cmd.rmdir(config.outdir)}}

.PHONY: {{this.phony}}

        '')
    }
}

//Add makefile
register_generator(Makefile(), "make")