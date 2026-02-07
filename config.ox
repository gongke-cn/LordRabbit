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
    libdirs: Set()
    libs: Set()
    cflags: null
    ldflags: null
    products: {}
    buildfiles: []
    libraries: {}
    genfiles: {}
    install: []
    options: {}
    settings: {}
    cache: {}
    configh: []
    package: null
    documents: {}

    //Get the intermediate directory.
    intermediate: func {
        return "{this.outdir}/intermediate"
    }

    //Get the macros array.
    macros: func {
        return this.macro_dict.entries().map(("$[0]=$[1]")).to_array()
    }

    //Add a product.
    add_product: func(name, prod) {
        old = this.products[name]
        if old {
            throw ReferenceError(L"{prod.location}: \"{name}\" is already declared at {old.location}")
        }

        this.products[name] = prod
        prod.path = name

        if prod.rule == "dlib" || prod.rule == "slib" {
            this.libraries[prod.name] = prod
        } elif prod.rule == "gen" {
            if prod.instdir == "none" {
                prefix = "-"
            } else {
                prefix = "+"
            }

            path = normpath("{prefix}{config.currdir}/{prod.name}")
            this.genfiles[path] = prod
        }
    }

    //Add document.
    add_doc: func(name, doc) {
        old = this.documents[name]
        if old {
            throw ReferenceError(L"{doc.location}: \"{name}\" is already declared at {old.location}")
        }

        this.documents[name] = doc
        doc.id = name
    }

    //Add installation jobs.
    add_install: func(def) {
        config.install.push(def)
    }

    //Lookup the library.
    lookup_lib: func(name) {
        return this.libraries[name]
    }

    //Lookup the generated file.
    lookup_gen: func(path) {
        return this.genfiles[path]
    }
}