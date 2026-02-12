# LordRabbit - Project Configuration and Build Tool

## Introduction
LordRabbit is a project configuration and build tool developed in the https://gitee.com/gongke1978/ox. Its functionality is similar to "GNU autotools" and "CMake".

## Installation
You can install LordRabbit using OX's package manager.
```
ox -r pm -s lordrabbit
```
Run the following command to print the help information for the "lordrabbit" program:
```
lordrabbit --help
```

## Example
Let's create a C language file "test.c" with the following content:
```
/*test.c*/
#include <stdio.h>

int main (int argc, char **argv)
{
    printf("hello, world!\n");
    return 0;
}
```
In the same directory, we create an "lrbuild.ox" file:
```
ref "lordrabbit" //Reference the lordrabbit package

assert_h("stdio.h") //Check for the header file "stdio.h", exit with error if not found

//Generate the executable "test"
build_exe({
    name: "test"
    srcs: [
        "test.c" //Source file
    ]
})

```
Run the following command for configuration:
```
lordrabbit
```
The terminal prints:
```
check "make": /usr/bin/make
load "lrbuild.ox"
check "stdio.h": stdio.h
check "gcc": /usr/bin/gcc
generate "Makefile"
```
"lordrabbit" automatically detected the project's dependent programs, header files, and libraries, and finally generated the "Makefile" file.

Run "make" to build the project:
```
make

BUILD out/test-exe-test.o <= test.c
BUILD out/test <= out/test-exe-test.o
```
You can see that the executable program "test" has been compiled and generated in the "out" directory.

## Basic Concepts

### lrbuild.ox
"lrbuild.ox" is the configuration and build description file written by the client. The "lordrabbit" program loads and executes the "lrbuild.ox" file in the current directory, performing configuration based on the file description and generating the "Makefile" file.

"lrbuild.ox" is a script written in the https://gitee.com/gongke1978/ox. The script starts by referencing the "lordrabbit" package with a reference statement:
```
ref "lordrabbit"
```
Subsequently, the script describes the project's configuration and build methods by calling functions provided by "lordrabbit".

A single project can use multiple "lrbuild.ox" files to describe the configuration and build methods of different submodules. The "subdirs" function in "lordrabbit" can be used to load and execute "lrbuild.ox" files in subdirectories.

### Output Directory
The generated object files and intermediate files are placed in the output directory. The default output directory is the "out" subdirectory under the current directory.

The "lordrabbit" program can modify the output directory using the "-o" option.

### Installation Directory
Running the "make install" command installs the build artifacts into the system. The installation directory is the root directory for artifact installation. For example, if the installation directory is "/usr/local", executable programs will be installed in the "/usr/local/bin" directory, and library files will be installed in the "/usr/local/lib" directory.

The default installation directory is "/usr". The "lordrabbit" program can modify the installation directory using the "--instdir" option.

### Toolchain
A toolchain is a collection of compilation-related tools such as compilers and linkers. "lordrabbit" currently supports two toolchains:

* gnu: GNU gcc/g++/ld and other tools
* gnu-clang: Uses the GNU toolchain, but the compiler uses clang and clang++

### Path Parameters
Many functions provided by "lordrabbit" support path parameters. A path parameter is a string representing the corresponding pathname. When the pathname is a relative path, it is generally relative to the directory where the current "lrbuild.ox" file is located. For example, using the following path parameters in the "subdir/lrbuild.ox" file:
```
"test.c"     //Corresponds to file "subdir/test.c"
"tmp/test.c" //Corresponds to file "subdir/tmp/test.c"
"../test.c"  //Corresponds to file "test.c"
```
If the string starts with "+", it indicates that this relative path is rooted at the output directory. For example, if the output directory is "out", using the following path parameters in the "subdir/lrbuild.ox" file:
```
"+test.c"     //Corresponds to file "out/subdir/test.c"
"+tmp/test.c" //Corresponds to file "out/subdir/tmp/test.c"
"+../test.c"  //Corresponds to file "out/test.c"
```

### pkg-config Module Name
"lordrabbit" supports "pkg-config" and can automatically call "pkg-config" to obtain the compiler and linker flags needed to link a module. "lordrabbit" represents a module's name using a pkg-config module name. A pkg-config module name is a string with the format "ModuleName:MinimumVersion". If the ":MinimumVersion" part is absent, "lordrabbit" only checks if the module is installed, without checking the version number.

## Functions
"lordrabbit" provides a set of functions to help users configure and build projects.

### add_cflags
Add global compiler flags.

The function parameter is a string representing the new compiler flag.

Example:
```
add_cflags("-Wall")
add_cflags("-O2")
```
In the generated Makefile, the command to compile ".o" files adds the "-Wall -O2" flags.

### add_inc
Add a global automatically included header file.

The function parameter is a path parameter representing the new header file.

Example:
```
add_inc("test.h")
```
In the generated Makefile, the command to compile ".o" files adds the "--include test.h" flag.

### add_incdir
Add a global header file search directory.

The function parameter is a path parameter representing the new header file search directory.

Example:
```
add_incdir("/usr/include/SDL")
```
In the generated Makefile, the command to compile ".o" files adds the "-I/usr/include/SDL" flag.

### add_ldflags
Add global linker flags.

The function parameter is a string representing the new linker flag.

Example:
```
add_ldflags("-flto")
```
In the generated Makefile, the link command adds the "-flto" flag.

### add_lib
Add a global link library.

The function parameter is a string representing the new library name.

Example:
```
add_lib("pthread")
add_lib("m")
```
In the generated Makefile, the link command adds the "-lpthread -lm" flags.

### add_libdir
Add a global library file search directory.

The function parameter is a path parameter representing the new library file search directory.

Example:
```
add_libdir("/home/zhangsan/lib")
```
In the generated Makefile, the link command adds the "-L/home/zhangsan/lib" flag.

### add_option
Add project options.

A project can specify multiple project-specific options. Users can set these project-specific options via the "-s" option when running the "lordrabbit" program.

The function parameter is an object. The property names of the object represent option names, and the property value objects represent the corresponding option definitions. Option object definitions include the following properties:

* type: The option type. Can be one of the following:
    - "boolean": Boolean value
    - "number": Numeric value
    - "integer": Integer value
    - String array: Represents an enumeration value, array elements represent the option's possible values
* default: The option's default value. If the user does not set this option via "-s" on the command line, its value is the default.
* desc: The option's description.

Example:
```
add_option({
    debug: {
        type: "boolean"
        default: false
        desc: "enable debug information"
    }
    mail: {
        type: "string"
        default: "zhangsan@ox.org"
        desc: "email address of author"
    }
    version: {
        type: "integer"
        default: 0
        desc: "version number"
    }
    model: {
        type: ["small", "normal", "large"]
        default: "normal"
        desc: "system model select"
    }
})
```
In "lrbuild.ox", project option values can be accessed via the "option" object. For example, after adding the options above, they can be accessed as follows:
```
if option.debug {
    add_cflags("-g")
}

define("MAIL=\"{option.mail}\"")
define("VERSION={option.version}")

case option.model {
"small" {
    define("MODEL_SIZE=256")
}
"normal" {
    define("MODEL_SIZE=512")
}
"large" {
    define("MODEL_SIZE=1024")
}
}
```
The "add_option" function call usually appears at the beginning of the "lrbuild.ox" file.

### assert_exe
Check if an executable program exists, exit with error if not found. "lordrabbit" searches for the specified executable program based on the "PATH" environment variable.

Parameter is a string representing the executable program name.
```
assert_exe("ox") //Must have the executable program "ox" installed
```

### assert_func
Check if a specified function is defined in the current environment, exit with error if not defined. "lordrabbit" attempts to test whether the function call can compile and link normally using the toolchain. The current global "incdirs", "incs", "macros", "cflags", "libdirs", "libs", and "ldflags" are automatically used during the test.

Parameter can be:

* String: Function name
* Object: Represents the test environment settings, which can include the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Function name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|libdirs|[Path Parameter]|Yes|Library search directories during test|
|libs|[String]|Yes|libs: Libraries to link during test|
|cflags|String|Yes|Compiler flags during test|
|ldflags|String|Yes|Linker flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

Example:
```
//Check function "printf"
assert_func("printf")

//Check function "realpath"
assert_func({
    name: "realpath"
    src: ''
#include <limits.h>
#include <stdlib.h>
int main (int argc, char **argv) {
    char buf[PATH_MAX];
    char *r;
    r = realpath("/test", buf);
    return 0;
}
    ''
})
```

### assert_h
Check if the required header file can be found in the current environment, exit with error if not found. "lordrabbit" attempts to test if including the header file can compile successfully using the toolchain. The current global "incdirs", "incs", "macros", and "cflags" are automatically used during the compilation of the test.

Parameter can be:

* String: Header file name
* Object: Represents the header file test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Header file name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|cflags|String|Yes|Compiler flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

Example:
```
assert_h("pthread.h") //Exit with error if "pthread.h" is unavailable
```

### assert_lib
Check if a required library can be linked in the current environment, exit with error if not found. "lordrabbit" attempts to test if linking the library can succeed using the toolchain. The current global "incdirs", "incs", "macros", "cflags", "libdirs", "libs", and "ldflags" are automatically used during the test.

Parameter can be:

* String: Library name
* Object: Represents the test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Library name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|libdirs|[Path Parameter]|Yes|Library search directories during test|
|libs|[String]|Yes|Libraries to link during test|
|cflags|String|Yes|Compiler flags during test|
|ldflags|String|Yes|Linker flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

Example:
```
assert_lib("pthread") //Verify that a usable "libpthread" library is available in the current environment, exit with error if not.
```

### assert_macro
Check if a specified macro is defined in the current environment, exit with error if not defined. "lordrabbit" attempts to test if the macro is defined using the toolchain. The current global "incdirs", "incs", "macros", and "cflags" are automatically used during the compilation of the test.

Parameter can be:

* String: Macro name
* Object: Represents the macro test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Macro name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|cflags|String|Yes|Compiler flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

Example:
```
assert_macro("__GNUC__") //Check macro "__GNUC__", exit if not defined
```

### assert_pc
Check if a "pkg-config" module is installed, exit with error if not installed. "lordrabbit" attempts to check if the module is installed via the "pkg-config" tool.

Parameter is a pkg-config module name. If the module name contains the ":MinimumVersion" part, it checks if the installed version is greater than or equal to the specified minimum version.

Example:
```
//Ensure the "SDL" module version >=1.2.68
assert_pc("SDL:1.2.68")
```

### build_exe
Build an executable program.

The function parameter is an object describing how to build the executable program. The parameter object can contain the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Name of the executable program|
|srcs|[Path Parameter]|Yes|List of source files|
|objs|[Path Parameter]|Yes|List of object files, list here if some object files are not directly generated from srcs files|
|incdirs|[Path Parameter]|Yes|Header file search directories|
|incs|[Path Parameter]|Yes|Automatically included header files|
|macros|[String]|Yes|Macros defined via command line|
|libdirs|[Path Parameter]|Yes|Library search directories|
|libs|[String]|Yes|Libraries the executable program needs to link|
|cflags|String|Yes|Compiler flags|
|ldflags|String|Yes|Linker flags|
|pcs|[pkg-config module name]|Yes|Modules the executable program needs to link via "pkg-config"|
|instdir|String|Yes|Installation directory for the executable program|

Example:
```
build_exe({
    name: "test"
    srcs: [
        "test.c"
    ]
    incdirs: [
        "/usr/include/ext"
    ]
    macros: [
        "ENABLE_TEST"
        "VERSION=1"
    ]
    libdirs: [
        "/usr/lib/ext"
    ]
    libs: [
        "ext"
        "m"
        "dl"
    ]
    cflags: "-Wall -O2 -flto"
    ldflags: "-flto"
})
```
In the generated "Makefile", the following command is generated to compile the object file "test-exe-test.o":
```
gcc -c -o out/test-exe-test.o test.c -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
The following command is generated to link and create the executable program "test":
```
gcc -o out/test out/test-exe-test.o -L/usr/lib/ext -lext -lm -ldl -flto
```
Note that the executable program name should not include the extension part; "lordrabbit" automatically adds the extension based on the target platform. For example, if the executable program name is "test", "lordrabbit" will generate the executable file "test" on Linux and "test.exe" on Windows.

"srcs" defines the source file array. If a source file string starts with "+", it indicates that this source file is generated by another generator, and its root directory is under the output directory.

Example in "lrbuild.ox":
```
build_exe({
    name: "test"
    srcs: [
        "test.c"          //"./test.c"
        "+generated.c"    //"out/generated.c"
    ]
})
```
"libs" defines the link library array. Each library name should not include the "lib" prefix and the extension. For example, if the executable program needs to link "libm.so", the library name should be written as "m". If a library name starts with "+", it indicates that this library is a library generated within the project, such as "+local", meaning the executable program links the "local" library generated in the project. "lordrabbit" will automatically find and add the parameters needed to link this library in the link command.
```
build_lib({
    name: "local"
    srcs: [
        "local.c"
    ]
})

build_exe({
    name: "test"
    libs: [
        "+local"
    ]
    srcs: [
        "test.c"
    ]
})
```
"instdir" indicates the installation subdirectory name for the executable program. When running "make install", the generated executable program is installed into this subdirectory under the installation directory. If "instdir" is not set, the default subdirectory is "bin". If "instdir" is set to "none", it means this executable program does not need to be installed.

### build_lib
Build a library file.

The function parameter is an object describing how to build the library. The parameter object can contain the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Library name|
|srcs|[Path Parameter]|Yes|List of source files|
|objs|[Path Parameter]|Yes|List of object files, list here if some object files are not directly generated from srcs files|
|incdirs|[Path Parameter]|Yes|Header file search directories|
|incs|[Path Parameter]|Yes|Automatically included header files|
|macros|[String]|Yes|Macros defined via command line|
|libdirs|[Path Parameter]|Yes|Library search directories|
|libs|[String]|Yes|Libraries to link|
|cflags|String|Yes|Compiler flags|
|ldflags|String|Yes|Linker flags|
|pcs|[pkg-config module name]|Yes|Modules the library needs to link via "pkg-config"|
|instdir|String|Yes|Installation directory for the library file|
|version|String|Yes|Interface version for the dynamic library|

Example:
```
build_lib({
    name: "test"
    srcs: [
        "test.c"
    ]
    incdirs: [
        "/usr/include/ext"
    ]
    macros: [
        "ENABLE_TEST"
        "VERSION=1"
    ]
    libdirs: [
        "/usr/lib/ext"
    ]
    libs: [
        "ext"
        "m"
        "dl"
    ]
    cflags: "-Wall -O2 -flto"
    ldflags: "-flto"
})
```
In the generated "Makefile", the following command is generated to compile the object file "test-lib-test.o":
```
gcc -c -o out/test-lib-test.o test.c -fPIC -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
The following command is generated to create the dynamic link library:
```
gcc -o out/libtest.so out/test-lib-test.o -shared -L/usr/lib/ext -lext -lm -ldl -flto
```
The following commands are generated to create the static link library:
```
ar rcs out/libtest.a out/test-lib-test.o
ranlib out/libtest.a
```
Note that the library name should not include the "lib" prefix and the extension part; "lordrabbit" automatically completes the library file name.

"srcs" defines the source file array. If a source file string starts with "+", it indicates that this source file is generated by another generator, and its root directory is under the output directory.

"libs" defines the link library array. Each library name should not include the "lib" prefix and the extension. For example, if the executable program needs to link "libm.so", the library name should be written as "m". If a library name starts with "+", it indicates that this library is a library generated within the project.

"instdir" indicates the installation subdirectory name for the library file. When running "make install", the generated library file is installed into this subdirectory under the installation directory. If "instdir" is not set, the default subdirectory is "lib". If "instdir" is set to "none", it means this library file does not need to be installed.

"version" is the interface version for the dynamic library. Example:
```
build_lib({
    name: "test"
    srcs: [
        "test.c"
    ]
    version: "1"
})
```
On Linux, the above description generates a dynamic link library named "libtest.so.1", and the linker adds options to specify the soname as "libtest.so.1". Simultaneously, "lordrabbit" creates a symbolic link "libtest.so" pointing to "libtest.so.1".

On Windows, the above description generates a dynamic link library named "libtest-1.dll", along with the corresponding implib file "libtest.dll.a".

"lordrabbit" generates both static and dynamic link libraries. If the user only wants to generate a dynamic link library, they can use the "build_dlib" function. If the user only wants to generate a static link library, they can use the "build_slib" function.

### config_h
Output the global macro definitions to a header file.

Usually, during the configuration process, the user defines many global macros via the "define" function. "lordrabbit" places these macros in the ".o" object compilation commands in the "Makefile" file. If the "config_h" function is called, these global macro definitions are written to a header file, and the Makefile's compilation command adds "-include config.h" to automatically include these macro definitions.

Usually, the "config_h" call should appear at the end of the "lrbuild.ox" file.

The parameter is a path parameter. If the parameter is not given, it defaults to "config.h".

### define
Add a global macro definition.

The function parameter is a string representing the macro definition to add.

Example:
```
define("ENABLE_TEST")
define("CONFIG_VALUE=1978")
```
The above declarations, in the generated Makefile, add the flags "-DENABLE_TEST -DCONFIG_VALUE=1978" to every ".o" compilation command.

### failed
Report an error and exit the configuration process.

Example:
```
failed("error!")
```
When this statement is executed, "lordrabbit" throws an exception and exits.

### gen_file
Generate a file using a tool.

The function parameter is an object describing how to generate the file. The parameter object can contain the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Name of the generated file|
|srcs|[Path Parameter]|Yes|List of source files|
|instdir|String|Yes|Installation directory for the generated file|
|cmd|String|No|Command to generate the file|

Example:
```
gen_file({
    name: "generated.c"
    srcs: [
        "generator.ox"
    ]
    cmd: "ox $< > $@"
})
```
The "cmd" property specifies the command to generate the file. Special markers can be included:

|Marker|Description|
|:-|:-|
|$@|Generated file name|
|$<|First source file name|
|$^|All source file names, separated by spaces|
|$N|N is a decimal number, represents the Nth source file name|
|$$|Replaced with "$"|

"instdir" indicates the installation subdirectory name for the generated file. After setting the "instdir" property, when running "make install", the generated file is installed into the subdirectory under the installation directory. If "instdir" is not set, or set to "none", it means the generated file does not need to be installed.

### get_cflags
Get the current global compiler flags.

The return value is a string representing the current global compiler flags.

### get_currdir
Get the directory path where the current "lrbuild.ox" is located.

The return value is a string representing the directory path where the current "lrbuild.ox" is located.

### get_incdirs
Get the current global header file search directories.

The return value is a string array, each element being a global header file search directory.

### get_incs
Get the currently set list of global automatically included header files.

The return value is a string array, each element being a path to a global automatically included header file.

### get_instdir
Get the installation directory path.

The return value is a string representing the installation directory path.

### get_ldflags
Get the current global linker flags.

The return value is a string representing the current global linker flags.

### get_libdirs
Get the current global library file search directories.

The return value is a string array, each element being a path to a global library file search directory.

### get_libs
Get the currently set list of global automatically linked library files.

The return value is a string array, each element being a path to a global library file.

### get_location
Get the location within the current "lrbuild.ox" file.

The return value is a string with the format "filename: line number". The filename is the pathname of the current "lrbuild.ox" file, and the line number is the line number within the currently executing "lrbuild.ox" file.

### get_macros
Get the currently set list of global macros.

The return value is a string array, each element being a global macro definition.

### get_outdir
Get the output directory path.

The return value is a string representing the output directory path.

### get_package
Get the current software package information.

Returns the software package information object. Returns null if no package information is set.

The software package information object contains the following properties:

|Property|Type|Description|
|:-|:-|:-|
|name|String|Package name|
|version|String|Version number|

### get_path
Convert a path parameter to an actual pathname.

"lordrabbit" parses the "+" prefix and converts the path parameter to an actual path based on the location of the "lrbuild.ox" file, normalizing the pathname.

The input parameter is a path parameter. Returns a string representing the actual path. Returns null if the input is null.

### get_paths
Convert an array of path parameters to an array of actual pathnames.

The input is an array of path parameters. Returns a string array corresponding to the actual path of each path parameter. Returns null if the input is null.

### gtkdoc
Create documentation using "gtkdoc".

The parameter is an object containing the following properties.

|Name|Type|Optional|Description|
|:-|:-|:-|:-|
|module|String|No|Module name|
|srcdirs|[Path Parameter]|Yes|List of source file directories, gtkdoc will scan the source files under these directories to obtain documentation information|
|hdrs|[Path Parameter]|No|List of header files, gtkdoc will load the header files to obtain documentation information|
|instdir|String|Yes|Default is "share/doc/gtkdoc-PACKAGE-MODULE". Where PACKAGE is the package name, MODULE is the module name|
|formats|[String]|Yes|List of output document formats, can include "html", "man", or "pdf". Default is "html"|

Example:
```
//Generate documentation for "MyModule"
gtkdoc({
    module: "MyModule"
    srcdirs: [
        "src"
    ]
    hdrs: [
        "include/MyModule.h"
    ]
    instdir: "share/doc/MyModule"
    //Generate both manual and HTML formats
    formats: [
        "man"
        "html"
    ]
})
```

### have_exe
Check if an executable program exists. "lordrabbit" searches for the specified executable program based on the "PATH" environment variable.

Parameter is a string representing the executable program name.

Returns a boolean value indicating whether the executable program exists.

Example:
```
//Check if the program "ox" exists.
if have_exe("ox") {
    define("HAVE_OX")
}
```

### have_func
Check if a specified function is defined in the current environment. "lordrabbit" attempts to test whether the function call can compile and link normally using the toolchain. The current global "incdirs", "incs", "macros", "cflags", "libdirs", "libs", and "ldflags" are automatically used during the test.

Parameter can be:

* String: Function name
* Object: Represents the test environment settings, which can include the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Function name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|libdirs|[Path Parameter]|Yes|Library search directories during test|
|libs|[String]|Yes|Libraries to link during test|
|cflags|String|Yes|Compiler flags during test|
|ldflags|String|Yes|Linker flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

Returns a boolean value indicating whether the function is defined.

Example:
```
//Check if function printf is available
if have_func("printf") {
    define("HAVE_PRINTF")
}

//Check if function realpath is available
if have_func({
    name: "realpath"
    src: ''
#include <limits.h>
#include <stdlib.h>
int main (int argc, char **argv) {
    char buf[PATH_MAX];
    char *r;
    r = realpath("/test", buf);
    return 0;
}
    ''
}) {
    failed("cannot find realpath")
}
```

### have_h
Check if the required header file can be found in the current environment. "lordrabbit" attempts to test if including the header file can compile successfully using the toolchain. The current global "incdirs", "incs", "macros", and "cflags" are automatically used during the compilation of the test.

Parameter can be:

* String: Header file name
* Object: Represents the header file test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Header file name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|cflags|String|Yes|Compiler flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

The function returns a boolean value indicating whether the header file can be found.

Example:
```
//Check if "pthread.h" is available in the current environment, define a macro if available.
if have_h("pthread.h") {
    define("HAVE_PTHREAD_H")
}
```

### have_lib
Check if a required library can be linked in the current environment. "lordrabbit" attempts to test if linking the library can succeed using the toolchain. The current global "incdirs", "incs", "macros", "cflags", "libdirs", "libs", and "ldflags" are automatically used during the test.

Parameter can be:

* String: Library name
* Object: Represents the test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Library name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|libdirs|[Path Parameter]|Yes|Library search directories during test|
|libs|[String]|Yes|libs: Libraries to link during test|
|cflags|String|Yes|Compiler flags during test|
|ldflags|String|Yes|Linker flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

The function returns a boolean value indicating whether the library file can be successfully linked.

Example:
```
if have_lib("pthread") {
    add_lib("pthread")
}
```
The above statement checks if the "libpthread" library is available and adds it to the global link library list if so.
```
if !have_lib({
    name: "test"
    libdirs: [
        "/usr/zhangshan/lib"
    ]
}) {
    failed("cannot find libtest")
}
```
The above statement searches for an available "libtest" library in the "/usr/zhangshan/lib" directory and exits with an error if not found.

### have_macro
Check if a specified macro is defined in the current environment. "lordrabbit" attempts to test if the macro is defined using the toolchain. The current global "incdirs", "incs", "macros", and "cflags" are automatically used during the compilation of the test.

Parameter can be:

* String: Macro name
* Object: Represents the macro test environment settings, containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|name|String|No|Macro name|
|incdirs|[Path Parameter]|Yes|Header file search directories during test|
|incs|[Path Parameter]|Yes|Automatically included header files during test|
|macros|[String]|Yes|Macro definitions during test|
|cflags|String|Yes|Compiler flags during test|
|pcs|[pkg-config module name]|Yes|pkg-config modules the test depends on|
|cxx|Bool|Yes|Whether to test using the C++ compiler|

The function returns a boolean value indicating whether the macro is defined.

Example:
```
//Detect if the target platform is Windows via the "WIN32" macro
if have_macro("WIN32") {
    failed("do not support windows")
}
```

### have_pc
Check if a "pkg-config" module is installed. "lordrabbit" attempts to check if the module is installed via the "pkg-config" tool.

Parameter is a pkg-config module name. If the module name contains the ":MinimumVersion" part, it checks if the installed version is greater than or equal to the specified minimum version.

Returns a boolean value indicating whether the module is installed and meets the minimum version requirement.

Example:
```
//Check if the "SDL" module is installed
if have_pc("SDL") {
    define("HAVE_SDL")
}

//Check if the "SDL" module version is >=1.2.68
if !have_pc("SDL:1.2.68") {
    failed("cannot find SDL(>=1.2.68)")
}
```

### install
Specify additional files to install.

The function parameter is an object that can contain the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|srcs|[Path Parameter]|Yes|List of files to install|
|srcdirs|[Path Parameter]|Yes|List of directories, all files and subdirectories under these directories will be installed|
|instdir|String|No|Installation directory for the files|
|mode|String|Yes|Mode of the files after installation, refer to the MODE definition of the "chmod" command|

Example:
```
install({
    instdir: "include"
    srcs: [
        "my_header1.h"
        "my_header2.h"
    ]
})
```
The above description indicates that the two header files "my_header1.h" and "my_header2.h" need to be installed into the "include" directory. When the user runs "make install", the two header files are installed into the system's "/usr/include" directory.

### package
Set software package information.

The parameter is an object representing the software package information, containing the following properties:

|Property|Type|Description|
|:-|:-|:-|
|name|String|Package name|
|version|String|Version number|

Example:
```
package({
    name: "MyProject"
    version: "0.0.1"
})
```

### pc_cflags
Get the compiler flags for a "pkg-config" module.

Parameter is a "pkg-config" module name.

Returns the module's compiler flags as a string.

Example:
```
add_cflags(pc_cflags("sdl")) //Add the "sdl" module's compiler flags
```

### pc_libs
Get the linker flags for a "pkg-config" module.

Parameter is a "pkg-config" module name.

Returns the module's linker flags as a string.

Example:
```
add_ldflags(pc_libs("sdl")) //Add the "sdl" module's linker flags
```

### subdirs
Load "lrbuild.ox" files in subdirectories.

A project can be divided into multiple submodules, each placed in a subdirectory. Each subdirectory can use an independent "lrbuild.ox" file to describe the submodule's configuration and build method. The "subdirs" function is used to load and execute the "lrbuild.ox" files in subdirectories.

The "subdirs" parameter is an array representing all subdirectories containing "lrbuild.ox" files. Example:
```
subdirs([
    "sub1"
    "sub2"
])
```
The above description loads and executes the two submodule descriptions "sub1/lrbuild.ox" and "sub2/lrbuild.ox".

### undef
Remove a global macro definition.

The function parameter is a string representing the name of the macro to remove.

Example:
```
define("ENABLE_TEST")
define("CONFIG_VALUE=1978")
undef("CONFIG_VALUE")
```
In the generated Makefile, the ".o" compilation command only retains the "-DENABLE_TEST" part.

## lordrabbit Extensions
In addition to the built-in functions provided by "lordrabbit", users can write extension functions in the OX language to implement custom detection, configuration, and build functions.

For example, if your project needs to package some resource files and link them with the executable program, you can define a function "mkres":
```
mkres: func(def) {
    //If not in the configuration running process, exit directly.
    if !running() {
        return
    }

    add_rule({
        assets = get_paths(def.assets) //Get the real paths of the resource files
        out = "{get_outdir()}/{get_currdir()}/{def.out}" //Real path of the generated file

        srcs: [
            ...assets //Input files are all resource files
        ]
        dsts: [
            out //Generated file
        ]
        cmd: "makeres -o {out} {assets.$to_str(" ")}" //Execute the "makeres" program to package resource files into a c file
    })
}
```
In "lrbuild.ox", you can call this function:
```
//Package resource files and convert them to a c file
mkres({
    assets: [
        "1.svg"
        "2.svg"
        "3.svg"
    ]
    out: "res.c"
})

//Link with the resource file to generate the executable program
build_exe({
    name: "test"
    srcs: [
        "main.c"
        "+res.c"
    ]
})
```
"lordrabbit" provides some helper classes and functions for users to write extensions.

### add_install
Add an installation task. This function is a low-level function for extensions; note the difference from "install".

The parameter is an installation task description object containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|src|String|Yes|Source file path|
|srcdir|String|Yes|Source directory path|
|dst|String|Yes|Target file path|
|dstdir|String|Yes|Target directory path|
|mode|String|Yes|Mode of the file after installation, refer to the MODE definition of the "chmod" command|
|strip|Bool|Yes|Whether to strip symbol information from object files|
|symlink|Bool|Yes|Whether to create a symbolic link|

Note that the parameters "src", "srcdir", "dst", and "dstdir" are all real pathnames, not path parameters.

By combining "src"/"srcdir" and "dst"/"dstdir", the installation of single or multiple files can be achieved.
Example:
```
//Install "src.txt" as "dst.txt" in the "share/doc" subdirectory of the installation directory
add_install({
    src: "src.txt"
    dst: "{get_instdir()}/share/doc/dst.txt"
})

//Install "test.txt" as "test.txt" in the "share/doc" subdirectory of the installation directory
add_install({
    src: "test.txt"
    dstdir: "{get_instdir()}/share/doc"
})

//Install all files under the "doc" subdirectory into the "share/doc" subdirectory of the installation directory
add_install({
    srcdir: "doc"
    dstdir: "{get_instdir()}/share/doc"
})
```

### add_job
Register a callback function to be called after all "lrbuild.ox" files have finished running.

Extension functions run during the loading and execution of "lrbuild.ox", when the configuration process is not yet complete. If some operations need to be performed after configuration is complete, a callback can be registered via this function.

The parameter is a callback function.

### add_product
Add a product file.

The parameter is a string representing the pathname of the product.

Generally, when a user extension calls "add_install", "lordrabbit" automatically marks the files to be installed as products, so users do not need to call the "add_product" function. For files generated using "phony rules", they need to be marked as products via the "add_product" function. In this case, the parameter string is the phony rule name. "Phony rules" are explained in detail in the "add_rule" function.

### add_rule
Add a generation rule.

The parameter is a rule description object containing the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|srcs|[String]|Yes|List of input files|
|dsts|[String]|Yes|List of output files|
|cmd|String|No|Generation command|
|phony|?String|Yes|For a normal rule, this value is null. If the rule is a phony rule, provide a rule name here|

Note that the elements of the parameters "srcs" and "dsts" are real pathnames, not path parameters.

For general rules, "srcs" and "dsts" correspond to real input and output file paths. Sometimes we cannot determine the specific input and output files. In this case, we can define the rule as a phony rule. Set the "phony" property to a string to indicate that this is a phony rule, and "lordrabbit" will control the rule through this phony rule name.

The output file path specified by "dsts", if it ends with a "/", indicates that a directory has been generated.
### running
Check if the configurator is running.

Generally, user extension functions start with the following statement:
```
if !running() {
    return
}
```
This code checks if it is currently the configurator running phase. If it is not the running phase, it does nothing and exits directly.

"lordrabbit" can list all parameters via the "--listopt" option when running. At this time, the "running" function returns false, indicating that it is not the real configuration phase. Users do not need to perform real detection and configuration actions at this time.

### shell
Return the current shell object.

The shell object contains the following methods, allowing users to obtain the command string corresponding to some current operations.

|Name|Parameters|Description|
|:-|:-|:-|
|rm|(path:String)|Return the command corresponding to removing a file|
|rmdir|(dirpath:String)|Return the command corresponding to removing a directory and its contents|
|mkdir|(dirpath:String)|Return the command corresponding to creating a directory and all its parent directories|
|install|(def:Object)|Return the command corresponding to installing one or more files|
|symlink|(target:String, linkpath:String)|Return the command corresponding to creating a symbolic link. This operation is only effective on some systems|

The "install" function's parameter is an object describing an installation task, which can contain the following properties:

|Property|Type|Optional|Description|
|:-|:-|:-|:-|
|src|String|Yes|Source file path|
|srcdir|String|Yes|Source directory path|
|dst|String|Yes|Target file path|
|dstdir|String|Yes|Target directory path|
|mode|String|Yes|Mode of the file after installation, refer to the MODE definition of the "chmod" command|
|strip|Bool|Yes|Whether to strip symbol information from object files|

### toolchain
Get the toolchain object.

The toolchain object contains the following properties:

|Property|Type|Description|
|:-|:-|:-|
|cc|String|C compiler program name|
|cxx|String|C++ compiler program name|
|target|Object|Toolchain's target platform information|

The target platform information object contains the following properties:

|Property|Type|Description|
|:-|:-|:-|
|name|String|Platform name, such as "linux", "windows"|
|exe_suffix|String|Executable program extension on this platform|
|slib_suffix|String|Static link library extension on this platform|
|dlib_suffix|String|Dynamic link library extension on this platform|

### Validator Object
Users sometimes need to perform some verification operations to verify certain characteristics of the current environment in extensions. This can be achieved by inheriting the "Validator" object.

For example, if a user wants to verify during configuration whether the current environment's Linux kernel version is greater than a specified version:
```
ref "std/shell"

KernelValidator: class Validator {
    //Initialize, record the required minimum version
    $init(major, minor) {
        this.major = major
        this.minor = minor
    }

    //Detection function
    check() {
        //Get kernel version by running a command
        out = Shell.output("uname -r")
        m = out.match(/(\d+)\.(\d+)/)

        //Parse major and minor version numbers
        major = Number(m.groups[1])
        minor = Number(m.groups[2])

        //If less than the minimum version, return null
        if major < this.major {
            return
        } elif major == this.major {
            if minor < this.minor {
                return
            }
        }

        //Test passed, return an actual string
        return out
    }

    //Get the object's corresponding string. This function is used for printing logs and creating the validator's corresponding label.
    $to_str() {
        return "kernel {this.major}.{this.minor}"
    }
}
```
In the user's "lrbuild.ox", this class can be called to verify the kernel version:
```
//Create a kernel validator object, minimum version 5.4
kernel = KernelValidator(5, 4)

//Verify kernel version
if !kernel.valid {
    //Exit if verification fails
    failed("kernel version < 5.4")
} else {
    //Verification successful, print the actual version number. The "value" property corresponds to the return value of the "check" method.
    stdout.puts("kernel: {kernel.value}")
}
```
Alternatively, the user can verify directly via the following method:
```
//Create a kernel validator object, minimum version 5.4
kernel = KernelValidator(5, 4)

//Verify kernel version, exit with error directly if kernel version is less than 5.4
kernel.assert()
```
The core of implementing a custom validator by inheriting the "Validator" object is to implement the "check" method, performing the relevant verification in the method. If the verification fails, return null. If the verification is successful, return a non-null value. In subsequent programs, this return value can be accessed via the "value" property.

The "Validator" object records the test result. When the "valid" method of the validator is called multiple times in the "lrbuild.ox" file, the "Validator" returns the result of the first test.

When "lordrabbit" finishes running, it records the test results of all validators in the "lrcache.ox" file in the output directory. When running "lordrabbit" for configuration again, "lordrabbit" first attempts to obtain the cached test results from the "lrcache.ox" file to optimize running time. If the user wishes not to read the cache and re-perform all verifications, please add the option "--nocache" when running "lordrabbit".

## lordrabbit Options
The "lordrabbit" program supports the following options:

|Option|Parameter|Description|
|:-|:-|:-|
|-D|MACRO[=VALUE]|Add a global macro definition|
|-I|DIR|Add a global header file search directory|
|-L|DIR|Add a global library file search directory|
|--cflags|FLAGS|Set global compiler flags|
|-d|DIR|Set output directory|
|-f|make|Set output file format. Currently only supports "make" (GNU make's Makefile)|
|-g|None|Compile products with debug information|
|--help|None|Display help information|
|--instdir|DIR|Set installation directory|
|-l|LIB|Add a global link library|
|--ldflags|FLAGS|Set global linker flags|
|--listopt|None|List all options for the current project|
|--nocache|None|Do not use cache file, re-perform detection|
|-o|FILE|Set output filename|
|-s|NAME[=VALUE]|Set an option for the current project|
|--toolchain|gnu\|gnu-clang|Set the toolchain to use. Currently supports GNU+GCC and GNU+clang|
|--xprefix|PREFIX|Set the cross-compilation toolchain prefix. For example, set "--xprefix i686-w64-mingw32" to select the MinGW64 cross-compilation toolchain|

## Makefile Parameters
The "Makefile" generated by "lordrabbit" supports the following parameters, which can be set when running the "make" command:

|Parameter|Description|
|:-|:-|
|Q|Default is "Q=@" indicating quiet mode. Set "Q=" to turn on intermediate print information|
|INST|Modify the installation directory|

## Makefile Targets
The "Makefile" generated by "lordrabbit" contains the following special targets, which can be used to perform special operations via "make target":

|Parameter|Description|
|:-|:-|
|all|Default target, generates all products defined in "lrbuild.ox" that need to be installed and their dependent files|
|install|Install all files defined in "lrbuild.ox" that need to be installed into the installation directory|
|uninstall|Remove installed files from the installation directory|
|clean|Remove all created products and intermediate files from the output directory|
|cleanout|Clear the entire output directory|