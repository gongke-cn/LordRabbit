ref "./exe_validator"
ref "./log"

//Shell operations.
public ShellCommand: {
    rm_exe: ExeValidator("rm")
    mkdir_exe: ExeValidator("mkdir")
    install_exe: ExeValidator("install")
    ln_exe: ExeValidator("ln")
    find_exe: ExeValidator("find")

    //Remove a file.
    rm: func(file) {
        this.rm_exe.assert()

        return "rm -f {file}"
    }

    //Remove a directory.
    rmdir: func(dir) {
        this.rm_exe.assert()

        return "rm -rf {dir}"
    }

    //Make directory with parents.
    mkdir: func(dir) {
        this.mkdir_exe.assert()

        return "mkdir -p {dir}"
    }

    //Install a file.
    install: func(def) {
        this.install_exe.assert()

        if def.mode {
            mflag = "-m {def.mode}"
        }

        if def.strip {
            strip = "-s"
        }

        if def.src && def.dst {
            return "install -D -T {mflag} {strip} {def.src} {def.dst}"
        } elif def.src && def.dstdir {
            return "install -D {mflag} {strip} {def.src} -t {def.dstdir}"
        } else {
            return "find {def.srcdir} -type f -execdir install -D -T {mflag} {strip} \{\} {def.dstdir}/\{\} \\;"
        }
    }

    //Create a symbol link.
    symlink: func(target, link) {
        this.ln_exe.assert()

        return "ln -s -f {target} {link}"
    }
}