ref "std/path"
ref "./log"

public Job: class {
    enum {
        HELP
        LISTOPT
        CONFIG
    }
}

//Configuration
public config: {
    job: Job.CONFIG
    currdir: "."
    instdir: "/usr"
    outdir: "out"
    outfile: null
    toolchains: {}
    generators: {}
    toolchain: null
    generator: null
    host: null
    target: null
    macro_dict: Dict()
    incdirs: Set()
    incs: Set()
    libdirs: Set()
    libs: Set()
    cflags: null
    ldflags: null
    buildfiles: []
    rules: []
    options: {}
    settings: {}
    cache: {}
    package: null
    shell: null
    install: ""
    uninstall: ""
    jobs: []
    products: []
}