
ref "std/io"
ref "std/path"
ref "std/fs"
ref "./config"
ref "./tools"
ref "./inner_tools"
ref "./exe_validator"
ref "./shell_command"
ref "./gtkdoc"
ref "./log"

//Generate the makefile.
gen_makefile: func() {
    if !config.outfile {
        config.outfile = "Makefile"
    }

    cmd = ShellCommand
    outdir = config.outdir
    config.outdir = "$(O)"

    o: {
        phony: "all clean cleanall cleanout install uninstall"
        products: ""
        rules: ""
        deps: ""
        genfiles: ""
        objs: {}
        install: ""
        uninstall: ""
        cleanfiles: []
        cleandirs: []
    }

    tab: "\t"

    //Check if the sources has C++.
    have_cxx: func(srcs) {
        for srcs as src {
            if src ~ /\.(cxx|cpp|c\+\+|hxx|hpp|h\+\+)$/p {
                return true
            }
        }
    }

    //Generate commands.
    gen_cmds: func(lines) {
        return lines.split("\n").map(("\t$(Q){$}")).$to_str("\n")
    }

    //Get objects.
    get_objs: func(def) {
        if def.rule == "slib" || def.rule == "dlib" {
            tag = "lib"
        } else {
            tag = def.rule
        }

        prefix = "{def.name.replace(".", '-')}-{tag}"

        return def.srcs.$iter().map(func(name) {
            src = name
            head = name[0]
            if head == "-" || head == "+" {
                name = name.slice(1)
            }
            dir = dirname(name)
            base = basename(name)

            if (m = base.match(/(.+)\.(c|cxx|cpp|c\+\+|h|hxx|hpp|h\+\+)/ip)) {
                obj = normpath("{config.intermediate()}/{dir}/{prefix}-{m.groups[1]}.o")

                if m.groups[2] == "c" {
                    rule = "c"
                } else {
                    rule = "cxx"
                }

                old = o.objs[obj]

                if !old {
                    o.objs[obj] = {
                        rule
                        obj
                        src
                        pic: def.pic
                        toolchain: def.toolchain
                        cflags: def.cflags
                        incdirs: def.incdirs
                        macros: def.macros
                    }
                }

                return obj
            } else {
                throw TypeError(L"unknown source format \"{name}\"")
            }
        }).to_array()
    }

    //Compile C to object.
    c2obj: func(def) {
        tc = def.toolchain
        obj = get_real_path(def.obj)
        src = get_real_path(def.src)
        depfile = obj.replace(/\.o$/, ".dep")
        if def.incdirs {
            incdirs = def.incdirs.$iter().map((get_real_path($))).to_array()
        }

        o.deps += " {depfile}"

        rule = {
            src
            obj
            dep: depfile
            pic: def.pic
            cflags: "$(CFLAGS) {def.cflags}"
            incdirs: incdirs
            macros: def.macros
        }

        o.rules += ''
{{obj}}: {{src}}
{{tab}}$(Q)$(info CC   $@ <- {{src}})
{{gen_cmds(cmd.mkdir("$(dir $@)"))}}
{{gen_cmds(tc.c2obj(rule))}}


        ''
    }

    //Compile C++ to object.
    cxx2obj: func(def) {
        tc = def.toolchain
        obj = get_real_path(def.obj)
        src = get_real_path(def.src)
        depfile = obj.replace(/\.o$/, ".dep")
        if def.incdirs {
            incdirs = def.incdirs.$iter().map((get_real_path($))).to_array()
        }

        o.deps += " {depfile}"

        rule = {
            src
            obj
            dep: depfile
            pic: def.pic
            cflags: "$(CFLAGS) {def.cflags}"
            incdirs: incdirs
            macros: def.macros
        }

        o.rules += ''
{{obj}}: {{src}}
{{tab}}$(Q)$(info CXX  $@ <- {{src}})
{{gen_cmds(cmd.mkdir("$(dir $@)"))}}
{{gen_cmds(tc.cxx2obj(rule))}}


        ''
    }

    //Solve the library dependencies.
    solve_lib_deps: func(rule) {
        if !rule.libs {
            return
        }

        libdirs = []
        deps = null

        for rule.libs as lib {
            def = config.lookup_lib(lib)
            if def {
                path = get_real_path(def.libpath)
                dir = dirname(path)
                libdirs.push(dir)
                deps += " {path}"
            }
        }

        if rule.libdirs {
            libdirs.[...rule.libdirs]
        }

        rule.libdirs = libdirs

        return deps
    }

    //Add global options.
    add_global_opts: func(def) {
        //If add "config.h", the macros will not be added in command line.
        if !config.configh.length {
            if !def.macros {
                def.macros = []
            }

            def.macros.[...config.macros()]
        }

        if config.incdirs.length {
            if !def.incdirs {
                def.incdirs = []
            }

            def.incdirs.[...config.incdirs]
        }

        if config.libdirs.length {
            if !def.libdirs {
                def.libdirs = []
            }

            def.libdirs.[...config.libdirs]
        }

        if config.libs.length {
            if !def.libs {
                def.libs = []
            }

            def.libs.[...config.libs]
        }

        if config.cflags {
            def.cflags += " {config.cflags}"
        }

        if config.ldflags {
            def.ldflags += " {config.ldflags}"
        }
    }

    //Generate executable program.
    gen_exe: func(def) {
        add_global_opts(def)

        tc = def.toolchain
        objs = get_objs(def)
        exe = get_real_path(def.path)
        if def.libdirs {
            libdirs = def.libdirs.$iter().map((get_real_path($))).to_array()
        }

        rule = {
            objs
            exe
            ldflags: "$(LDFLAGS) {def.ldflags}"
            libdirs: libdirs
            libs: def.libs
            cxx: have_cxx(def.srcs)
        }

        libdeps = solve_lib_deps(rule)

        o.rules += ''
{{exe}}: {{objs.$to_str(" ")}} {{libdeps}}
{{tab}}$(Q)$(info EXE  $@ <- $^)
{{gen_cmds(cmd.mkdir("$(dir $@)"))}}
{{gen_cmds(tc.objs2exe(rule))}}


        ''
    }

    //Generate static library.
    gen_slib: func(def) {
        add_global_opts(def)

        tc = def.toolchain
        objs = get_objs(def)
        lib = get_real_path(def.path)
        if def.libdirs {
            libdirs = def.libdirs.$iter().map((get_real_path($))).to_array()
        }

        rule = {
            objs
            lib
            ldflags: "$(LDFLAGS) {def.ldflags}"
            libdirs: libdirs
            libs: def.libs
            cxx: have_cxx(def.srcs)
        }

        libdeps = solve_lib_deps(rule)

        o.rules += ''
{{lib}}: {{objs.$to_str(" ")}} {{libdeps}}
{{tab}}$(Q)$(info SLIB $@ <- $^)
{{gen_cmds(cmd.mkdir("$(dir $@)"))}}
{{gen_cmds(tc.objs2slib(rule))}}


        ''
    }

    //Generate dynamic library.
    gen_dlib: func(def) {
        add_global_opts(def)

        tc = def.toolchain
        objs = get_objs(def)
        lib = get_real_path(def.path)
        dst = lib

        if def.slib {
            slib = get_real_path(def.slib)
            dst += " {slib}"
        }

        if def.libdirs {
            libdirs = def.libdirs.$iter().map((get_real_path($))).to_array()
        }

        rule = {
            objs
            lib
            ldflags: "$(LDFLAGS) {def.ldflags}"
            libdirs: libdirs
            libs: def.libs
            slib
            version: def.version
            cxx: have_cxx(def.srcs)
        }

        libdeps = solve_lib_deps(rule)

        mkdir_cmds = gen_cmds(cmd.mkdir(dirname(lib)))

        if slib {
            mkdir_cmds += "\n"
            mkdir_cmds += gen_cmds(cmd.mkdir(dirname(slib)))
        }

        o.rules += ''
{{dst}}: {{objs.$to_str(" ")}} {{libdeps}}
{{tab}}$(Q)$(info DLIB $@ <- $^)
{{mkdir_cmds}}
{{gen_cmds(tc.objs2dlib(rule))}}


        ''
    }

    //Generate a symbol link.
    gen_symlink: func(def) {
        link = get_real_path(def.path)
        target = get_real_path(def.target)

        if def.dep {
            dep = get_real_path(def.dep)
        }

        o.rules += ''
{{link}}: {{dep}}
{{tab}}$(Q)$(info LN   $@ <- {{def.target}})
{{gen_cmds(cmd.symlink(target, "$@"))}}


        ''
    }

    //Generate a file.
    gen_file: func(def) {
        out = get_real_path(def.path)

        if def.srcs {
            deps = def.srcs.$iter().map((get_real_path($))).$to_str(" ")
        }

        cmdline = get_gen_cmd_line(def)

        o.genfiles += " {out}"
        o.rules += ''
{{out}}: {{deps}}
{{tab}}$(Q)$(info GEN  $@ <- $^)
{{gen_cmds(cmdline)}}


        ''
    }

    inst_dirs = Set()

    //Add an installation.
    add_install: func(rule) {
        if o.install {
            o.install += "\n"
        }

        dir = dirname(rule.dst)
        inst_dirs.add(dir)

        if rule.symlink {
            o.install += cmd.symlink(rule.src, rule.dst)
        } else {
            o.install += cmd.install(rule.src, rule.dst, rule.mode, rule.strip)
        }

        if o.uninstall {
            o.uninstall += "\n"
        }
        o.uninstall += cmd.rm(rule.dst)
    }

    //Solve products.
    for Object.values(config.products) as def {
        path = get_real_path(def.path)

        if def.instdir != "none" {
            base = basename(path)
            o.products += " {path}"

            if def.rule == "symlink" {
                add_install({
                    src: get_real_path(def.target)
                    dst: "$(INST)/{def.instdir}/{base}"
                    symlink: true
                })
            } else {
                if def.rule == "exe" {
                    mode = "755"
                } else {
                    mode = "644"
                }

                if def.rule == "dlib" {
                    strip = "-s"
                } else {
                    strip = null
                }

                add_install({
                    src: path
                    dst: "$(INST)/{def.instdir}/{base}"
                    mode: mode
                    strip: strip
                })
            }
        } else {
            o.genfiles += " {path}"
        }

        case def.rule {
        "exe" {
            gen_exe(def)
        }
        "slib" {
            gen_slib(def)
        }
        "dlib" {
            gen_dlib(def)
        }
        "symlink" {
            gen_symlink(def)
        }
        "gen" {
            gen_file(def)
        }
        }
    }

    //Solve installations.
    for config.install as inst {
        for inst.srcs as file {
            src = get_real_path(file)
            base = basename(src)

            add_install({
                src
                dst: "$(INST)/{inst.instdir}/{base}"
                mode: inst.mode
            })
        }
    }

    if inst_dirs.length {
        o.install = inst_dirs.$iter().map((cmd.mkdir($))).$to_str("\n") + "\n" + o.install
    }

    //Solve objects.
    for Object.values(o.objs) as def {
        case def.rule {
        "c" {
            c2obj(def)
        }
        "cxx" {
            cxx2obj(def)
        }
        }
    }

    objs = Object.keys(o.objs).$to_str(" ")

    alltargets = o.products

    mktargets = basename(config.outfile)
    mkjobs = config.cli_args.$iter().map(("\"{$}\"")).$to_str(" ")

    //Gtk document.
    if Object.keys(config.gtkdocs).to_array().length {

        gtkdoc = GtkDoc()

        for Object.values(config.gtkdocs) as doc_def {
            if gtkdoc_cmds {
                gtkdoc_cmds += "\n"
            }
            gtkdoc_cmds += gtkdoc.build({
                module: doc_def.module
                srcdir: get_real_path(doc_def.srcdir)
                hdrs: doc_def.hdrs.$iter().map((get_real_path($))).to_array()
                formats: doc_def.formats
            })

            if doc_def.formats && doc_def.formats.length {
                for doc_def.formats as fmt {
                    o.cleandirs.push("{config.outdir}/gtkdoc/{doc_def.module}/{fmt}")
                }
            } else {
                o.cleandirs.push("{config.outdir}/gtkdoc/{doc_def.module}/html")
            }

            if doc_def.package {
                ent_file = "{outdir}/gtkdoc/{doc_def.module}/xml/gtkdocentities.ent"
                mkdir_p(dirname(ent_file))
                File.store_text(ent_file, ''
<!ENTITY package_name "{{doc_def.package.name}}">
<!ENTITY package_string "{{doc_def.package.name}}">
<!ENTITY version "{{doc_def.package.version}}">
                '')
            }
        }

        gtkdoc_rule = ''
gtkdoc:
{{tab}}$(Q)$(info GTK DOCUMENT)
{{gen_cmds(gtkdoc_cmds)}}
        ''
        o.phony += " gtkdoc"
    }

    if o.cleandirs.length {
        cleandirs = gen_cmds(cmd.rmdir(o.cleandirs.$to_str(" ")))
    }

    File.store_text(config.outfile, ''
Q ?= @
O ?= {{outdir}}
CFLAGS ?=
LDFLAGS ?=
INST ?= {{config.instdir}}

all: {{alltargets}}

{{mktargets}}: {{config.buildfiles.$iter().$to_str(" ")}}
{{tab}}$(Q)$(info GEN  $@)
{{gen_cmds(mkjobs)}}

-include{{o.deps}}

{{o.rules}}

install: {{o.products}} uninstall
{{tab}}$(Q)$(info INSTALL)
{{gen_cmds(o.install)}}

uninstall:
{{tab}}$(Q)$(info UNINSTALL)
{{gen_cmds(o.uninstall)}}

clean:
{{tab}}$(Q)$(info CLEAN)
{{gen_cmds(cmd.rm("{o.products} {objs}"))}}

cleanall: clean
{{tab}}$(Q)$(info CLEAN ALL)
{{gen_cmds(cmd.rm("{o.deps} {o.genfiles} {o.cleanfiles.$to_str(" ")}"))}}
{{cleandirs}}

cleanout:
{{tab}}$(Q)$(info CLEAN OUT)
{{gen_cmds(cmd.rmdir(config.outdir))}}

{{gtkdoc_rule}}

.PHONY: {{o.phony}}
    '')
}

//Makefile.
Makefile: class ExeValidator {
    //Initialize.
    $init() {
        ExeValidator.$inf.$init.call(this, "make")
    }

    //Generate the "Makefile".
    generate() {
        this.assert()

        gen_makefile()
    }
}

//Add makefile
register_generator(Makefile(), "make")