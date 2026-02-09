#!/usr/bin/ox

ref "std/option"
ref "std/io"
ref "std/lang"
ref "std/path"
ref "std/fs"
ref "json"
ref "./log"
ref "./config"
ref "./inner_tools"
ref "./gnu"
ref "./makefile"
ref "./linux"
ref "./windows"

/*?
 *? @package lordrabbit Project configuration and building tool.
 *? @exe Project configuration and building tool.
 */


//Show usage.
usage: func {
    stdout.puts(L''
Usage: lordrabbit [OPTION]...
Option:
{{options.help()}}
    '')
}

//?
options: Option([
    {
        short: "g"
        help: L"Generate debug information in products"
        on_option: func {
            config.debug = true
        }
    }
    {
        short: "D"
        arg: Option.STRING
        help: L"Add a macro definition"
        on_option: func(opt, arg) {
            m = arg.match(/(.+)=(.+)/p)
            if m {
                config.macro_dict.add(m.groups[1], m.groups[2])
            } else {
                config.macro_dict.add(arg, null)
            }
        }
    }
    {
        short: "I"
        arg: Option.STRING
        help: L"Add a header file Lookup directory"
        on_option: func(opt, arg) {
            config.incdirs.add(arg)
        }
    }
    {
        long: "cflags"
        arg: Option.STRING
        help: L"Set the compiler flags"
        on_option: func(opt, arg) {
            config.cflags = arg
        }
    }
    {
        short: "L"
        arg: Option.STRING
        help: L"Add a library lookup directory"
        on_option: func(opt, arg) {
            config.libdirs.add(arg)
        }
    }
    {
        short: "l"
        arg: Option.STRING
        help: L"Add a library to be linked with the products"
        on_option: func(opt, arg) {
            config.libs.add(arg)
        }
    }
    {
        long: "ldflags"
        arg: Option.STRING
        help: L"Set the linker's flags"
        on_option: func(opt, arg) {
            config.ldflags = arg
        }
    }
    {
        short: "f"
        arg: Object.keys(config.generators).to_array()
        help: L"Set the generatd file format"
        on_option: func(opt, arg) {
            config.generator = config.generators[arg]
        }
    }
    {
        long: "toolchain"
        arg: Object.keys(config.toolchains).to_array()
        help: L"Set the toolchain used"
        on_option: func(opt, arg) {
            config.toolchain = config.toolchains[arg]
        }
    }
    {
        long: "xprefix"
        arg: Option.STRING
        help: L"Set the cross compiling toolchain's prefix tag"
        on_option: func(opt, arg) {
            config.toolchain = GnuToolchain(arg)
        }
    }
    {
        short: "s"
        arg: Option.STRING
        help: L"Set an option's value of the project. The argument's format is \"NAME=VALUE\". If \"=VALUE\" is not provided, the option's value is true"
        on_option: func(opt, arg) {
            m = arg.match(/(.+)=(.*)/p)
            if m {
                config.settings[m.groups[1]] = m.groups[2]
            } else {
                config.settings[arg] = true
            }
        }
    }
    {
        long: "listopt"
        help: L"List the options of the project"
        on_option: func {
            config.job = Job.LISTOPT
        }
    }
    {
        long: "nocache"
        help: L"Do not use cache"
        on_option: func {
            config.no_cache = true
        }
    }
    {
        short: "o"
        arg: Option.STRING
        help: L"Set the output filename"
        on_option: func(opt, arg) {
            config.outfile = arg
        }
    }
    {
        short: "d"
        arg: Option.STRING
        help: L"Set the output directory"
        on_option: func(opt, arg) {
            config.outdir = arg
        }
    }
    {
        long: "instdir"
        arg: Option.STRING
        help: L"Set the installation directory"
        on_option: func(opt, arg) {
            config.instdir = arg
        }
    }
    {
        long: "help"
        help: L"Show thie help message"
        on_option: func {
            usage()
            config.job = Job.HELP
        }
    }
])

//Parse the options.
if !options.parse(argv) {
    return 1
}

//Show usage.
if config.job == Job.HELP {
    return 0
}

//Path of the cache file.
cache_path: "{config.outdir}/lrcache.ox"

if config.job == Job.CONFIG {
    config.cli_args = argv

    //Set the host.
    if OX.os == "windows" {
        config.host = Windows
    } else {
        config.host = Linux
    }

    //Set the toolchain.
    if !config.toolchain {
        config.toolchain = config.toolchains["gnu"]
    }

    //Generate the output.
    if !config.generator {
        for Object.entries(config.generators) as [name, gen] {
            if gen.valid() {
                config.generator = gen
                break
            }
        }

        if !config.generator {
            throw NullError(L"cannot find valid generator")
        }
    }

    //Try to load cache file.
    if !config.no_cache {
        try {
            if Path(cache_path).exist {
                config.cache = JSON.from_file(cache_path)
                stdout.puts(L"load \"{cache_path}\"\n")
            }
        } catch err {
            stdout.puts(L"\"{cache_path}\" is not valid\n")
            config.cache = {}
        }
    }

    //Prepare.
    config.generator.prepare()
}

//Run the "./lrbuild.ox"
run_lr_build(".")

if config.job == Job.CONFIG {
    //Run jobs.
    for config.jobs as job {
        job()
    }

    //Store the cache file.
    mkdir_p(dirname(cache_path))
    File.store_text(cache_path, JSON.to_str(config.cache, "  "))
    stdout.puts(L"store \"{cache_path}\"\n")
    
    //Generate the output file.
    config.generator.generate()

    stdout.puts(L"generate \"{config.outfile}\"\n")
} elif config.job == Job.LISTOPT {
    stdout.puts("Option:\n")
    for Object.entries(config.options) as [name, def] {
        if def.type instof String {
            tdesc = def.type
        } else {
            tdesc = def.type.$to_str("|")
        }

        stdout.puts("  {name} [{tdesc} = {def.default}]: {def.desc}\n")
    }
}
