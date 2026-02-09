ref "std/lang"

{
    name: "lordrabbit"
    version: "0.0.2"
    architecture: "all"
    description: {
        en: "LordRabbit - Project configuration and building tool"
        zh: "LordRabbit - 项目配置构建工具"
    }
    dependencies: {
        "std": "0.0.2"
        "json": "0.0.1"
    }
    executables: [
        "lordrabbit"
    ]
    libraries: [
        "tools"
        "validator"
    ]
    internal_libraries: [
        "log"
        "config"
        "inner_tools"
        "makefile"
        "windows"
        "linux"
        "pkgconfig"
        "shell_command"
        "gtkdoc"
        "gnu"
        "basic"
        "compile"
        "config_h"
        "gen_file"
        "test"
        "option"
        "exe_validator"
        "c_validator"
        "output_validator"
    ]
    system_files: {
        if OX.os == "windows" {
            "bin/lordrabbit.bat": "lordrabbit.bat"
        } else {
            "bin/lordrabbit": "lordrabbit.sh"
        }
    }
}
