ref "./log"

//Shell operations.
public ShellCommand: {
    //Remove a file.
    rm: func(file) {
        return "rm -f {file}"
    }

    //Remove a directory.
    rmdir: func(dir) {
        return "rm -rf {dir}"
    }

    //Make directory with parents.
    mkdir: func(dir) {
        return "mkdir -p {dir}"
    }

    //Install a file.
    install: func(src, dst, mode, strip) {
        if mode {
            mflag = "-m {mode}"
        }

        return "install -T {mflag} {strip} {src} {dst}"
    }

    //Create a symbol link.
    symlink: func(target, link) {
        return "ln -s -f {target} {link}"
    }
}