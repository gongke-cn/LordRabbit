ref "./exe_validator"
ref "./shell_command"
ref "./config"
ref "./log"

//GtkDoc.
public GtkDoc: class {
    //Initialize.
    $init() {
        this.{
            scan: ExeValidator("gtkdoc-scan")
            scangobj: ExeValidator("gtkdoc-scangobj")
            mkdb: ExeValidator("gtkdoc-mkdb")
            mkhtml: ExeValidator("gtkdoc-mkhtml")
            mkpdf: ExeValidator("gtkdoc-mkpdf")
            mkman: ExeValidator("gtkdoc-mkman")
        }
    }

    //Build document.
    build(def) {
        this.scan.assert()
        this.mkdb.assert()

        shell = ShellCommand

        gen_cmds = null

        gen_doc: func(fmt) {
            exe = this["mk{fmt}"]
            if !exe {
                throw NullError(L"illegal gtkdoc output format \"{fmt}\"")
            }

            exe.assert()

            if gen_cmds {
                @gen_cmds += "\n"
            }

            dir = "{config.outdir}/gtkdoc/{def.module}/{fmt}"

            @gen_cmds += ''
{{shell.mkdir(dir)}}
cd {{dir}}; {{exe}} {{def.module}} ../{{def.module}}-docs.xml
            ''
        }

        if def.formats && def.formats.length {
            for def.formats as fmt {
                gen_doc(fmt)
            }
        } else {
            gen_doc("html")
        }

        dir = "{config.outdir}/gtkdoc/{def.module}"

        return ''
{{shell.mkdir(dir)}}
{{this.scan}} --module {{def.module}} --source-dir {{def.srcdir}} --output-dir {{dir}} {{def.hdrs.$to_str(" ")}}
TOP=`pwd`; cd {{dir}}; {{this.mkdb}} --module {{def.module}} --source-dir $$TOP/{{def.srcdir}}
{{gen_cmds}}
        ''
    }
}