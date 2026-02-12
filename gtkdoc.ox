ref "json/json_schema"
ref "std/fs"
ref "std/io"
ref "std/path"
ref "./exe_validator"
ref "./shell_command"
ref "./basic"
ref "./log"

//GtkDoc.
GtkDoc: class {
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

        if def.srcdirs {
            srcdirs = def.srcdirs.$iter().map(("--source-dir $TOP/{$}")).$to_str(" ")
        }

        head = shell.mkdir(def.outdir)

        pi = get_package()
        if pi {
            srcfile = "{get_outdir()}/{get_currdir()}/gtkdocentities.ent"
            entfile = "{def.outdir}/xml/gtkdocentities.ent"

            mkdir_p(dirname(srcfile))
            File.store_text(srcfile, ''
<!ENTITY package_name "{{pi.name}}">
<!ENTITY package_string "{{pi.name}}">
<!ENTITY version "{{pi.version}}">
            '')
            head += "\n"
            head += shell.install({
                src: srcfile
                dst: entfile
                mode: "0644"
            })
        }

        return ''
{{head}}
TOP=`pwd`; {{this.scan}} --module {{def.module}} {{srcdirs}} --output-dir {{def.outdir}} --rebuild-sections --rebuild-types {{def.hdrs.$to_str(" ")}}
TOP=`pwd`; cd {{def.outdir}}; {{this.mkdb}} --module {{def.module}} {{srcdirs}}
{{gen_cmds}}
        ''
    }
}

//JSON schema of GtkDoc rule.
gtkdoc_rule_schema: JsonSchema({
    type: "object"
    properties: {
        module: {
            type: "string"
        }
        srcdirs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        hdrs: {
            type: "array"
            items: {
                type: "string"
            }
        }
        instdir: {
            type: "string"
        }
        formats: {
            type: "array"
            items: {
                type: "string"
            }
        }
    }
    required: [
        "module"
    ]
})

gtkdoc_inst = GtkDoc()

/*?
 *? Generate document throw gtkdoc.
 *? @param def {GtkDocRule} Rule to build gtk document.
 */
public gtkdoc: func(def) {
    if !running() {
        return
    }

    try {
        gtkdoc_rule_schema.validate_throw(def)
    } catch e {
        throw Error("{get_location()}: {e}")
    }

    pi = get_package()

    if pi {
        id = "gtkdoc-{pi.name}-{def.module}"
    } else {
        id = "gtkdoc-{def.module}"
    }

    outdir = "{get_outdir()}/{get_currdir()}/{id}"

    if !def.instdir {
        def.instdir = "share/doc/{id}"
    }

    if !def.formats {
        def.formats = ["html"]
    }

    cmd = gtkdoc_inst.build({
        module: def.module
        outdir
        srcdirs: get_paths(def.srcdirs)
        hdrs: get_paths(def.hdrs)
        formats: def.formats
    })

    add_rule({
        phony: id
        dsts: ["{outdir}/"]
        cmd
    })

    add_product(id)

    if def.instdir != "none" {
        for def.formats as fmt {
            add_install({
                srcdir: "{outdir}/{fmt}"
                dstdir: "{get_instdir()}/{def.instdir}/{fmt}"
                mode: "0644"
            })
        }
    }
}