ref "std/lang"

{
    name: "lordrabbit"
    version: "0.0.1"
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
        "gnu"
    ]
    internal_libraries: [
        "log"
        "config"
        "inner_tools"
        "makefile"
        "windows"
        "linux"
        "pkgconfig"
        "validator"
        "exe_validator"
        "c_validator"
        "shell_command"
        "schema"
    ]
    system_files: {
        if OX.os == "windows" {
            "bin/lordrabbit.bat": "lordrabbit.bat"
        } else {
            "bin/lordrabbit": "lordrabbit.sh"
        }
    }
}