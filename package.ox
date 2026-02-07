{
  "name": "lordrabbit",
  "description": {
    "en": "LordRabbit - Project configuration and building tool",
    "zh": "LordRabbit - 项目配置构建工具"
  },
  "version": "0.0.2",
  "architecture": "all",
  "dependencies": {
    "std": "0.0.2",
    "json": "0.0.1"
  },
  "libraries": [
    "tools",
    "gnu"
  ],
  "executables": [
    "lordrabbit"
  ],
  "files": [
    "%pkg%/tools.ox",
    "%pkg%/gnu.ox",
    "%pkg%/lordrabbit.ox",
    "%pkg%/log.ox",
    "%pkg%/config.ox",
    "%pkg%/inner_tools.ox",
    "%pkg%/makefile.ox",
    "%pkg%/windows.ox",
    "%pkg%/linux.ox",
    "%pkg%/pkgconfig.ox",
    "%pkg%/validator.ox",
    "%pkg%/exe_validator.ox",
    "%pkg%/c_validator.ox",
    "%pkg%/shell_command.ox",
    "%pkg%/gtkdoc.ox",
    "%pkg%/schema.ox",
    "bin/lordrabbit",
    "%locale%/zh_CN/LC_MESSAGES/lordrabbit.mo",
    "%doc%/md/lordrabbit/lordrabbit.md",
    "%doc%/md/lordrabbit/lordrabbit_tools.md",
    "%doc%/md/lordrabbit/lordrabbit_gnu.md",
    "%doc%/md/lordrabbit/lordrabbit_lordrabbit.md",
    "%pkg%/package.ox"
  ]
}