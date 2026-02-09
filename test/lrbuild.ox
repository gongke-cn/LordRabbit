ref "lordrabbit"

add_option({
    enable_libcurl: {
        type: "boolean"
        default: true
        desc: "Enable lincurl"
    }
    enable_ncurses: {
        type: "boolean"
        default: true
        desc: "Enable ncurses"
    }
    version: {
        type: "integer"
        default: "0"
        desc: "Version number"
    }
})

add_cflags(pc_cflags("sdl"))
add_ldflags(pc_libs("sdl"))

add_cflags("-Wall -O2")

if have_h("stdio.h") {
    define("HAVE_STDIO_H")
}

build_exe({
    name: "lrtest"
    libs: [
        "+lrtest"
    ]
    pcs: [
        if option.enable_libcurl {
            "libcurl:8.5.0"
        }
        if option.enable_ncurses {
            "ncursesw"
        }
    ]
    srcs: [
        "main.c"
    ]
    macros: [
        "VERSION={option.version}"
    ]
})

build_lib({
    name: "lrtest"
    version: "0"
    libs: [
        "+sub1/sub1"
        "+sub2/sub2"
    ]
    srcs: [
	"lib.c"
        "+gen.c"
    ]
})

gen_file({
    name: "gen.c"
    srcs: [
        "gen.ox"
    ]
    cmd: "ox $< > $@"
})

subdirs([
    "sub1"
    "sub2"
])

install({
    instdir: "include/lrtest"
    srcs: [
        "test.h"
        "+config.h"
    ]
})

config_h("+config.h")
