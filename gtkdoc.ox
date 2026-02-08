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

            dir = "{def.outdir}/{fmt}"

            @gen_cmds += ''
{{shell.mkdir(dir)}}
cd {{dir}}; {{exe}} {{def.module}} ../{{def.module}}-docs.xml
            ''
        }

        for def.formats as fmt {
            gen_doc(fmt)
        }

        return ''
{{shell.mkdir(def.outdir)}}
{{this.scan}} --module {{def.module}} --source-dir {{def.srcdir}} --output-dir {{def.outdir}} --rebuild-sections --rebuild-types {{def.hdrs.$to_str(" ")}}
cd {{def.outdir}}; {{this.mkdb}} --module {{def.module}} --source-dir $(realpath {{def.srcdir}})
{{gen_cmds}}
        ''
    }
}
