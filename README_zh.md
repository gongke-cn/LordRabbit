# LordRabbit - 项目配置构建工具
## 简介
LordRabbit是一个用[OX语言](https://gitee.com/gongke1978/ox)开发的项目配置和构建工具。
其功能类似于"GNU autotools"和 "CMake"。
## 安装
可以使用OX的包管理器安装LordRabbit。
```
ox -r pm -s lordrabbit
```
运行以下命令打印"lordrabbit"程序的帮助信息：
```
lordrabbit --help
```
## 示例
我们创建一个C语言文件"test.c"，其内容如下：
```
/*test.c*/
#include <stdio.h>

int main (int argc, char **argv)
{
    printf("hello, world!\n");
    return 0;
}
```
在同一目录下，我们创建一个"lrbuild.ox"文件：
```
ref "lordrabbit" //引用lordrabbit软件包

assert_h("stdio.h") //检测头文件"stdio.h",如果没有找到报错并退出

//生成可执行程序"test"
build_exe({
    name: "test"
    srcs: [
        "test.c" //源文件
    ]
})

```
运行下面的命令进行配置：
```
lordrabbit
```
终端打印：
```
check "make": /usr/bin/make
load "lrbuild.ox"
check "stdio.h": stdio.h
check "gcc": /usr/bin/gcc
generate "Makefile"
```
"lordrabbit"自动检测了项目依赖的程序，头文件和库，最终生成了"Makefile"文件。

运行"make"构建项目：
```
make

BUILD out/test-exe-test.o <= test.c
BUILD out/test <= out/test-exe-test.o
```
可以看到在"out"目录下编译生成了可执行程序"test"。
## 基本概念
### lrbuild.ox
"lrbuild.ox"是客户编写的配置和构建描述文件。"lordrabbit"程序会加载并运行当前目录下的"lrbuild.ox"文件，
根据文件描述进行配置并生成"Makefile"文件。

"lrbuild.ox"是一个用[OX语言](https://gitee.com/gongke1978/ox)编写的脚本。
脚本开头通过引用语句引用了"lordrabbit"软件包：
```
ref "lordrabbit"
```
脚本后面通过调用"lordrabbit"提供的函数，描述了项目的配置和构建方法。

一个项目中可以使用多个"lrbuild.ox"文件描述不同的子模块的配置和构建方法。"lordrabbit"中可以通过函数"subdirs"
加载并运行子目录下的"lrbuild.ox"文件。
### 输出目录
构建生成的目标文件和中间文件会放置到输出目录中，缺省的输出目录为当前目录下的"out"子目录。

"lordrabbit"程序可以通过选项"-o"修改输出目录。
### 安装目录
运行"make install"命令，可以将构建产物安装到系统中。安装目录为产物安装的根目录。
如安装目录为"/usr/local",可执行程序会安装到"/usr/local/bin"目录下，库文件会安装到"/usr/local/lib"目录下。

缺省的安装目录为"/usr"，"lordrabbit"程序可以通过选项"--instdir"修改安装目录。
### 工具链
工具链是编译器/链接器等一系列编译相关工具的集合。"lordrabbit"目前支持两种工具链：

* gnu: GNU gcc/g++/ld等工具
* gnu-clang: 使用GNU工具链，但编译器使用clang和clang++

### 路径参数
"lordrabbit"提供的很多函数中支持使用路径参数。路径参数为一个字符串，表示其对应的路径名。
当路径名为一个相对路径时，一般来说这个路径是以当前的"lrbuild.ox"文件所在目录为基准的。如"subdir/lrbuild.ox"文件中使用以下路径参数：
```
"test.c"     //对应文件"subdir/test.c"
"tmp/test.c" //对应文件"subdir/tmp/test.c"
"../test.c"  //对应文件"test.c"
```
如果字符串以"+"开始，则表示这个相对路径是以输出目录为根目录，如输出目录为"out", "subdir/lrbuild.ox"文件中使用以下路径参数：
```
"+test.c"     //对应文件"out/subdir/test.c"
"+tmp/test.c" //对应文件"out/subdir/tmp/test.c"
"+../test.c"  //对应文件"out/test.c"
```
### pkg-config模块名
"lordrabbit"支持"pkg-config"，可以自动调用"pkg-config"获取链接一个模块需要的编译器和链接器标识。
"lordrabbit"通过pkg-config模块名表示一个模块的名称。
pkg-config模块名为一个字符串，其格式为"模块名:最低版本"。如果":最低版本"部分不存在，"lordrabbit"只检测模块是否已安装，不检测模块版本号。

## 函数
"lordrabbit"提供了一组函数用于帮助用户配置和构建项目。
### add_cflags
增加全局编译器标记。

函数参数为一个字符串,表示新增的编译器标记。

如：
```
add_cflags("-Wall")
add_cflags("-O2")
```
在生成的Makefile中，编译".o"的命令中增加了"-Wall -O2"标记。
### add_inc
增加一个全局自动包含头文件。

函数参数为一个路径参数,表示新增的头文件。

如：
```
add_inc("test.h")
```
在生成的Makefile中，编译".o"的命令中增加了"--include test.h"的标记。
### add_incdir
增加一个全局头文件查找目录。

函数参数为一个路径参数,表示新增的头文件查找目录。

如：
```
add_incdir("/usr/include/SDL")
```
在生成的Makefile中，编译".o"的命令中增加了"-I/usr/include/SDL"的标记。
### add_ldflags
增加全局链接器标记。

函数参数为一个字符串,表示新增的链接器标记。

如：
```
add_ldflags("-flto")
```
在生成的Makefile中，链接命令中增加了"-flto"标记。
### add_lib
增加一个全局链接库。

函数参数为一个字符串,表示新增的库名称。

如：
```
add_lib("pthread")
add_lib("m")
```
在生成的Makefile中，链接命令中增加了"-lpthread -lm"的标记。
### add_libdir
增加一个全局库文件查找目录。

函数参数为一个路径参数,表示新增的库文件查找目录。

如：
```
add_libdir("/home/zhangsan/lib")
```
在生成的Makefile中，链接命令中增加了"-L/home/zhangsan/lib"的标记。
### add_option
增加项目选项。

项目可以指定多个项目专属选项。用户运行"lordrabbit"程序时可通过"-s"选项设置这些项目专属选项。

函数参数为一个对象，对象的属性名代表选项的名称，属性值对象表示对应选项的定义。选项对象定义包括以下属性：

* type: 选项类型。可以为以下值：
    - "boolean": 布尔值
    - "number": 数值
    - "integer": 整数值
    - 字符串数组： 表示一个枚举值，数组元素代表选项的可选值
* default: 选项的缺省值。如果用户在命令行没有通过"-s"设置这个选项，其值就是缺省值。
* desc: 选项的描述信息。

如：
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
在"lrbuild.ox"中，可以通过对象"option"访问项目选项值，如增加上面的定义选项后，可以用如下方式访问选项：
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
"add_option"函数调用通常出现在"lrbuild.ox"文件开头。
### assert_exe
检验可执行程序是否存在,不存在时报错退出。"lordrabbit"会根据环境变量"PATH"查找指定的可执行程序。

参数为一个字符串，表示可执行程序名称。
```
assert_exe("ox") //必须安装可执行程序"ox"
```
### assert_func
检验当前环境下是否定义了指定的函数,未定义时报错退出。"lordrabbit"会尝试使用工具链测试函数调用是否可以正常编译链接。
当前的全局"incdirs","incs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 函数名称
* 对象：表示测试环境设置，可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|函数名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|libdirs|[路径参数]|是|测试时的库查找目录|
|libs|[String]|是|libs：测试时要链接的库|
|cflags|String|是|测试时的编译器标识|
|ldflags|String|是|测试时的链接器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

如：
```
//检测函数"printf"
assert_func("printf")

//检测函数"realpath"
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
检查当前环境下是否可找到需要的头文件，如果找不到报错退出。"lordrabbit"会尝试使用工具链测试包含该头文件是否可以编译成功。
当前的全局"incdirs","incs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示头文件名称
* 对象：表示头文件测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|头文件名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|cflags|String|是|测试时的编译器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

如：
```
assert_h("pthread.h") //如"pthread.h"不可用报错退出
```
### assert_lib
检查当前环境下是否可以链接需要的库,没找到时报错退出。"lordrabbit"会尝试使用工具链测试链接库是否可以成功。
当前的全局"incdirs","incs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 表示库名称
* 对象：表示测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|库名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|libdirs|[路径参数]|是|测试时的库查找目录|
|libs|[String]|是|测试时要链接的库|
|cflags|String|是|测试时的编译器标识|
|ldflags|String|是|测试时的链接器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

如：
```
assert_lib("pthread") //验证当前是否有可用的"libpthread"库，没有时报错退出。
```
### assert_macro
检查当前环境下是否定义了指定的宏，没有定义时报错退出。"lordrabbit"会尝试使用工具链测试宏是否已定义。
当前的全局"incdirs","incs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示宏名称
* 对象：表示宏测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|宏名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|cflags|String|是|测试时的编译器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

如：
```
assert_macro("__GNUC__") //检验宏"__GNUC__",如果未定义退出
```
### assert_pc
检验"pkg-config"模块是否已安装，未安装时报错退出。"lordrabbit"会尝试通过"pkg-config"工具检验模块是否安装。

参数为一个pkg-config模块名，如果模块名存在":最低版本"部分，会检测已安装版本是否大于等于指定的最低版本。

如：
```
//确保"SDL"模块版本>=1.2.68
assert_pc("SDL:1.2.68")
```
### build_exe
构建一个可执行程序。

函数参数为一个对象，描述了可执行程序的构建方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|可执行程序的名称|
|srcs|[路径参数]|是|源文件列表|
|objs|[路径参数]|是|目标文件列表，如一些目标文件不是直接由源文件srcs生成，在这里列出|
|incdirs|[路径参数]|是|头文件查找目录|
|incs|[路径参数]|是|自动包含的头文件|
|macros|[String]|是|通过命令行定义的宏|
|libdirs|[路径参数]|是|库查找目录|
|libs|[String]|是|可执行程序需要链接的库|
|cflags|String|是|编译器标记|
|ldflags|String|是|链接器标记|
|pcs|[pkg-config模块名]|是|可执行程序需要通过"pkg-config"链接的模块|
|instdir|String|是|可执行程序的安装目录|

如：
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
在生成的"Makefile"中，会生成以下命令编译对象文件"test-exe-test.o":
```
gcc -c -o out/test-exe-test.o test.c -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
生成以下命令链接创建可执行程序"test":
```
gcc -o out/test out/test-exe-test.o -L/usr/lib/ext -lext -lm -ldl -flto
```
注意可执行程序名称不要包含扩展名部分，"lordrabbit"会根据生成目标平台自动添加扩展名。
如可执行程序名为"test"，"lordrabbit"在linux下会生成可执行程序文件"test"，windows下会生成可执行程序文件"test.exe"。

"srcs"定义了源文件数组，如果源文件字符串以"+"开头，表示此源文件是一个通过其他生成器产生的源文件，其根目录在输出目录下。

如"lrbuild.ox"中定义：
```
build_exe({
    name: "test"
    srcs: [
        "test.c"          //"./test.c"
        "+generated.c"    //"out/generated.c"
    ]
})
```
"libs"定义链接库数组，每一个链接库名称不要包含"lib"前缀和扩展名。如可执行程序需要链接"libm.so", 库名称应写为"m"。
库名称如果以"+"开头，表示这个库是项目中生成的一个库，如"+local"，表示可执行程序链接项目中生成的"local"库。
"lordrabbit"会自动查找并在链接命令中加入链接此库相应的参数。
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
"instdir"表示可执行程序的安装子目录名。当运行"make install"时，生成的可执行程序被安装到安装目录的这个子目录下。
如果没有设置"instdir"，默认为子目录为"bin"。如果"instdir"设置为"none"，表示这个可执行程序不需要安装。
### build_lib
构建一个库文件。

函数参数为一个对象，描述了库的构建方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|库名称|
|srcs|[路径参数]|是|源文件列表|
|objs|[路径参数]|是|目标文件列表，如一些目标文件不是直接由源文件srcs生成，在这里列出|
|incdirs|[路径参数]|是|头文件查找目录|
|incs|[路径参数]|是|自动包含的头文件|
|macros|[String]|是|通过命令行定义的宏|
|libdirs|[路径参数]|是|库查找目录|
|libs|[String]|是|需要链接的库|
|cflags|String|是|编译器标记|
|ldflags|String|是|链接器标记|
|pcs|[pkg-config模块名]|是|库需要通过"pkg-config"链接的模块|
|instdir|String|是|库的安装目录|
|version|String|是|动态库的接口版本|

如：
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
在生成的"Makefile"中，会生成以下命令编译对象文件"test-lib-test.o":
```
gcc -c -o out/test-lib-test.o test.c -fPIC -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
生成以下命令创建动态链接库：
```
gcc -o out/libtest.so out/test-lib-test.o -shared -L/usr/lib/ext -lext -lm -ldl -flto
```
生成以下命令创建静态链接库：
```
ar rcs out/libtest.a out/test-lib-test.o
ranlib out/libtest.a
```
注意库名称不要包含"lib"前缀和扩展名部分，"lordrabbit"会自动添加补全库文件名称。

"srcs"定义了源文件数组，如果源文件字符串以"+"开头，表示此源文件是一个通过其他生成器产生的源文件，其根目录在输出目录下。

"libs"定义的链接库数组，每一个链接库名称不要包含"lib"前缀和扩展名。如可执行程序需要链接"libm.so", 库名称应写为"m"。
库名称如果以"+"开头，表示这个库是项目中生成的一个库，如"+local"，表示可执行程序链接项目中生成的"local"库。

"instdir"表示库文件的安装子目录名。当运行"make install"时，生成的库文件被安装到安装目录的这个子目录下。
如果没有设置"instdir"，默认为子目录为"lib"。如果"instdir"设置为"none"，表示这个库文件不需要安装。

"version"为动态库的接口版本。如：
```
build_lib({
    name: "test"
    srcs: [
        "test.c"
    ]
    version: "1"
})
```
在linux下，上面的描述生成的动态链接库名为"libtest.so.1"，链接器增加选项指定soname为"libtest.so.1"。
同时"lordrabbit"创建一个符号链接"libtest.so"指向"libtest.so.1"。

在windows下，上面的描述生成的动态链接库名为"libtest-1.dll",同时生成对应的implib文件"libtest.dll.a"。

"lordrabbit"会同时生成静态链接库和动态链接库。如果用户只想生成动态链接库，可使用函数"build_dlib"。
如果用户只想生成静态链接库，可使用函数"build_slib"。
### config_h
将全局宏定义输出到一个头文件中。

通常配置过程中用户会通过"define"函数定义很多全局宏，"lordrabbit"会将这些宏放在"Makefile"文件中".o"对象编译的命令中。
如果调用"config_h"函数，这些全局宏定义会写到一个头文件中，"Makefile"的编译命令中增加"-include config.h"自动包含定义这些宏定义。

通常"config_h"调用应出现在"lrbuild.ox"文件末尾。

参数为一个路径参数。如果参数没有给出，缺省为"config.h"。
### define
增加一个全局宏定义。

函数参数为一个字符串，表示要增加的宏定义。

如：
```
define("ENABLE_TEST")
define("CONFIG_VALUE=1978")
```
以上声明在生成的Makefile中，每个编译".o"的命令都增加了"-DENABLE_TEST -DCONFIG_VALUE=1978"的标记。
### failed
报错并退出配置过程。

如：
```
failed("error!")
```
执行到此语句时，"lordrabbit"会抛出异常并退出。
### gen_file
使用工具生成一个文件。

函数参数为一个对象，描述了文件的生成方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|生成文件名称|
|srcs|[路径参数]|是|源文件列表|
|instdir|String|是|生成文件的安装目录|
|cmd|String|否|生成文件的命令|

如:
```
gen_file({
    name: "generated.c"
    srcs: [
        "generator.ox"
    ]
    cmd: "ox $< > $@"
})
```
"cmd"属性指定了生成文件的命令。其中可以加入一些特殊标记：

|标记|说明|
|:-|:-|
|$@|生成文件名|
|$<|首个源文件名|
|$^|全部源文件名，以空格分隔|
|$N|N为十进制数，表示第N个源文件名|
|$$|替换为"$"|

"instdir"表示生成文件的安装子目录名。设置"instdir"属性后，当运行"make install"时，生成文件被安装到安装目录的子目录下。
如果没有设置"instdir"，或"instdir"设置为"none"，表示生成文件不需要安装。
### get_cflags
获取当前的全局编译器标识。

返回值为一个字符串，为当前全局编译器标识。
### get_currdir
获取当前"lrbuild.ox"所在的目录路径。

返回值为一个字符串，为当前全"lrbuild.ox"所在的目录路径。
### get_incdirs
获取当前全局头文件查找目录。

返回值为一个字符串数组，每个元素为一个全局头文件查找目录。
### get_incs
获取当前设置的全局自动包含头文件列表。

返回值为一个字符串数组，每个元素为一个全局自动包含头文件路径。
### get_instdir
获取安装目录路径。

返回值为一个字符串，表示安装目录路径。
### get_ldflags
获取当前的全局链接器标识。

返回值为一个字符串，为当前全局链接器标识。
### get_libdirs
获取当前全局库文件查找目录。

返回值为一个字符串数组，每个元素为一个全局库文件查找目录路径。
### get_libs
获取当前设置的全局自动链接库文件列表。

返回值为一个字符串数组，每个元素为一个全局库文件路径。
### get_location
获取当前"lrbuild.ox"文件中的位置。

返回值为一个字符串，其格式为"文件名: 行号"。其中文件名为当前"lrbuild.ox"文件的路径名，行号为当前执行"lrbuild.ox"文件中的行号。
### get_macros
获取当前设置的全局宏列表。

返回值为一个字符串数组，每个元素为一个全局宏定义。
### get_outdir
获取输出目录路径。

返回值为一个字符串，表示输出目录路径。
### get_package
获取当前软件包信息。

返回软件包信息对象。如果没有设置软件包信息返回null。

软件包信息的对象，包含以下属性:

|属性|类型|描述|
|:-|:-|:-|
|name|String|软件包名称|
|version|String|版本号|

### get_path
将路径参数转化为实际路径名。

"lordrabbit"会解析"+"前缀，根据"lrbuild.ox"的位置，将路径参数转化为实际的路径，并对路径名进行规范化。

输入参数为路径参数，返回一个字符串，表示实际路径。
如果输入为null，返回null。
### get_paths
将路径参数数组转化为实际路径名数组。

输入为路径参数数组，返回一个字符串数组，对应每个路径参数的实际路径。
如果输入为null，返回null。
### gtkdoc
使用"gtkdoc"创建文档。

参数为一个对象,包含以下属性。

|名称|类型|可选|说明|
|:-|:-|:-|:-|
|module|String|否|模块名|
|srcdirs|[路径参数]|是|源文件目录列表, gtkdoc会扫描目录下的源文件获取文档信息|
|hdrs|[路径参数]|否|头文件列表，gtkdoc会加载头文件获取文档信息|
|instdir|String|是|缺省为"share/doc/gtkdoc-PACKAGE-MODULE"。其中PACKAGE为软件包名，MODULE为模块名|
|formats|[String]|是|输出文档格式列表，可以包含"html","man"或"pdf"。缺省为"html"|

如：
```
//为"MyModule"生成文档
gtkdoc({
    module: "MyModule"
    srcdirs: [
        "src"
    ]
    hdrs: [
        "include/MyModule.h"
    ]
    instdir: "share/doc/MyModule"
    //生成manual和HTML两种格式
    formats: [
        "man"
        "html"
    ]
})
```
### have_exe
检验可执行程序是否存在。"lordrabbit"会根据环境变量"PATH"查找指定的可执行程序是否存在。

参数为一个字符串，表示可执行程序名称。

返回值为布尔值，表示可执行程序是否存在。

如：
```
//检测程序"ox"是否存在。
if have_exe("ox") {
    define("HAVE_OX")
}
```
### have_func
检验当前环境下是否定义了指定的函数。"lordrabbit"会尝试使用工具链测试函数调用是否可以正常编译链接。
当前的全局"incdirs","incs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 函数名称
* 对象：表示测试环境设置，可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|函数名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|libdirs|[路径参数]|是|测试时的库查找目录|
|libs|[String]|是|测试时要链接的库|
|cflags|String|是|测试时的编译器标识|
|ldflags|String|是|测试时的链接器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

返回布尔值，表示函数是否定义。

如：
```
//检测函数printf是否可用
if have_func("printf") {
    define("HAVE_PRINTF")
}

//检测函数realpath是否可用
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
检查当前环境下是否能找到需要的头文件。"lordrabbit"会尝试使用工具链测试包含该头文件是否可以编译成功。
当前的全局"incdirs","incs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示头文件名称
* 对象：表示头文件测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|头文件名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|cflags|String|是|测试时的编译器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

函数返回布尔值，表示头文件是否可以找到。

如：
```
//检测当前环境"pthread.h"是否可用，如果可用定义宏。
if have_h("pthread.h") {
    define("HAVE_PTHREAD_H")
}
```
### have_lib
检查当前环境下是否可以链接需要的库。"lordrabbit"会尝试使用工具链测试链接库是否可以成功。
当前的全局"incdirs","incs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 表示库名称
* 对象：表示测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|库名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|libdirs|[路径参数]|是|测试时的库查找目录|
|libs|[String]|是|libs：测试时要链接的库|
|cflags|String|是|测试时的编译器标识|
|ldflags|String|是|测试时的链接器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

函数返回布尔值，表示库文件是否可以成功链接。

如：
```
if have_lib("pthread") {
    add_lib("pthread")
}
```
上面的语句检测如果"libpthread"库可用，将其放入全局链接库列表中。
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
上面的语句在"/usr/zhangshan/lib"目录下查找是否有可用的"libtest"库，没找到时报错退出。
### have_macro
检查当前环境下是否定义了指定的宏。"lordrabbit"会尝试使用工具链测试宏是否已定义。
当前的全局"incdirs","incs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示宏名称
* 对象：表示宏测试环境设置，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|宏名称|
|incdirs|[路径参数]|是|测试时的头文件查找目录|
|incs|[路径参数]|是|测试时自动包含的头文件|
|macros|[String]|是|测试时的宏定义|
|cflags|String|是|测试时的编译器标识|
|pcs|[pkg-config模块名]|是|测试时依赖的pkg-config模块|
|cxx|Bool|是|是否用C++编译器进行测试|

函数返回布尔值，表示宏是否定义。

如：
```
//通过宏"WIN32"检测目标平台是否为window
if have_macro("WIN32") {
    failed("do not support windows")
}
```
### have_pc
检验"pkg-config"模块是否已安装。"lordrabbit"会尝试通过"pkg-config"工具检验模块是否安装。

参数为一个pkg-config模块名，如果模块名存在":最低版本"部分，会检测已安装版本是否大于等于指定的最低版本。

返回布尔值，表示模块是否安装且符合最低版本要求。

如：
```
//检测"SDL"模块是否安装
if have_pc("SDL") {
    define("HAVE_SDL")
}

//检测"SDL"模块版本是否>=1.2.68
if !have_pc("SDL:1.2.68") {
    failed("cannot find SDL(>=1.2.68)")
}
```
### install
指定需要额外安装的文件。

函数参数为一个对象，参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|srcs|[路径参数]|是|需要安装文件列表|
|srcdirs|[路径参数]|是|目录列表，目录下全部文件及其子目录会被安装|
|instdir|String|否|文件的安装目录|
|mode|String|是|安装后文件的模式，参考"chmod"命令的MODE定义|

如：
```
install({
    instdir: "include"
    srcs: [
        "my_header1.h"
        "my_header2.h"
    ]
})
```
以上描述表示需要将"my_header1.h"，"my_header2.h"两个头文件安装到"include"目录下。当用户运行"make install"时，
两个头文件被安装到系统的"/usr/include"目录下。
### package
设置软件包信息。

参数为一个表示软件包信息的对象，包含以下属性:

|属性|类型|描述|
|:-|:-|:-|
|name|String|软件包名称|
|version|String|版本号|

如:
```
package({
    name: "MyProject"
    version: "0.0.1"
})
```
### pc_cflags
获取一个"pkg-config"模块的编译器标识。

参数为"pkg-config"模块名。

返回值为模块的编译器标识字符串。

如：
```
add_cflags(pc_cflags("sdl")) //增加"sdl"模块的编译器标识
```
### pc_libs
获取一个"pkg-config"模块的链接器标识。

参数为"pkg-config"模块名。

返回值为模块的链接器标识字符串。

如：
```
add_ldflags(pc_libs("sdl")) //增加"sdl"模块的链接器标识
```
### subdirs
加载子目录下的"lrbuild.ox"。

一个工程可以划分为多个子模块，每个子模块放在一个子目录下，在每个子目录下可以用一个独立的"lrbuild.ox"描述子模块的配置和构建方法。
"subdirs"函数用来加载并运行子目录下的"lrbuild.ox"文件。

"subdirs"参数为一个数组，表示包含"lrbuild.ox"文件的所有子目录。如：
```
subdirs([
    "sub1"
    "sub2"
])
```
上面的描述加载并运行"sub1/lrbuild.ox"和"sub2/lrbuild.ox"两个子模块描述。
### undef
取消一个全局宏定义。

函数参数为一个字符串,表示要取消宏的名字。

如：
```
define("ENABLE_TEST")
define("CONFIG_VALUE=1978")
undef("CONFIG_VALUE")
```
在生成的Makefile中，编译".o"的命令中只保留了"-DENABLE_TEST"部分。

## lordrabbit扩展
除了"lordrabbit"提供的内置函数，用户可以通过OX语言编写扩展函数，实现自定义的检测，配置和构建函数。

如，你的项目中需要将一些资源文件打包并和可执行程序链接，可以定义函数"mkres"：
```
mkres: func(def) {
    //如果不在配置运行过程中，直接退出。
    if !running() {
        return
    }

    add_rule({
        assets = get_paths(def.assets) //获取资源文件的真实路径
        out = "{get_outdir()}/{get_currdir()}/{def.out}" //生成文件的真实路径

        srcs: [
            ...assets //输入文件为所有资源文件
        ]
        dsts: [
            out //生成文件
        ]
        cmd: "makeres -o {out} {assets.$to_str(" ")}" //执行"makeres"程序将资源文件打包成c文件
    })
}
```
在"lrbuild.ox"中可以调用这个函数:
```
//打包资源文件转换为c文件
mkres({
    assets: [
        "1.svg"
        "2.svg"
        "3.svg"
    ]
    out: "res.c"
})

//和资源文件一起链接生成可执行程序
build_exe({
    name: "test"
    srcs: [
        "main.c"
        "+res.c"
    ]
})
```
"lordrabbit"中为用户编写扩展提供了一些辅助类和函数。
### add_install
增加一个安装任务。此函数是为扩展提供的底层函数，注意和"install"的区别。

参数为一个安装任务描述对象，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|src|String|是|源文件路径|
|srcdir|String|是|源目录路径|
|dst|String|是|目标文件路径|
|dstdir|String|是|目标目录路径|
|mode|String|是|安装后文件的模式，参考"chmod"命令的MODE定义|
|strip|Bool|是|是否对对象文件清除符号信息|
|symlink|Bool|是|是否是创建一个符号链接|

注意参数"src","srcdir","dst"和"dstdir"都是真实路径名，不是路径参数。

通过组合使用"src"/"srcdir"和"dst"/"dstdir"，可以实现单个文件或多个文件的安装。
如：
```
//将"src.txt"安装为安装目录"share/doc"子目录下的"dst.txt"
add_install({
    src: "src.txt"
    dst: "{get_instdir()}/share/doc/dst.txt"
})

//将"test.txt"安装为安装目录"share/doc"子目录下的"test.txt"
add_install({
    src: "test.txt"
    dstdir: "{get_instdir()}/share/doc"
})

//将"doc"子目录下全部文件安装到安装目录"share/doc"子目录下
add_install({
    srcdir: "doc"
    dstdir: "{get_instdir()}/share/doc"
})
```
### add_job
注册一个回调函数，当全部"lrbuild.ox"运行完成后调用该回调。

扩展函数是在"lrbuild.ox"加载执行过程中运行的，此时配置过程还没有完成，如果有部分操作需要在配置完成后操作，可以通过此函数注册一个回调。

参数为一个回调函数。
### add_product
增加一个产物文件。

参数为一个字符串，表示产物的路径名。

一般来说用户的扩展在调用"add_install"时"lordrabbit"会自动将要安装的文件标记为产物,用户无需调用"add_product"函数。
对于使用"假性规则"生成的文件，需要通过"add_product"函数标记产物。此时参数字符串为假性规则名。
"假性规则"在"add_rule"函数中有详细说明。
### add_rule
增加一个生成规则。

参数为一个规则描述对象，包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|srcs|[String]|是|输入文件列表|
|dsts|[String]|是|输出文件列表|
|cmd|String|否|生成命令|
|phony|?String|是|普通规则此值为null。如果规则是一个假性规则，此处给出一个规则名称|

注意参数"srcs","dsts"的元素都是真实路径名，不是路径参数。

一般规则"srcs","dsts"对应的真实输入输出文件路径。有时我们无法确定输入和输出文件的具体有哪些，此时我们可以将规则定义为假性规则。
将"phony"属性设置为一个字符串表示这是一个假性规则，"lordrabbit"将通过这个假性规则名称控制规则。
### running
检查配置器是否在运行。

一般用户扩展函数都用以下语句开始：
```
if !running() {
    return
}
```
这段代码会检测当前是否在配置器运行阶段，如果不在运行阶段，不执行任何操作直接退出。

"lordrabbit"在运行时可以通过"--listopt"选项列出所有参数，此时"running"函数返回false，表示当前不是真正的配置阶段。此时用户不需要
执行真正的检测配置动作。
### shell
返回当前的shell对像。

shell对象包含以下方法，可以让用户获取当前执行一些操作对应的命令字符串。

|名称|参数|说明|
|:-|:-|:-|
|rm|(path:String)|返回移除一个文件对应的命令|
|rmdir|(dirpath:String)|返回移除一个目录及其内容对应的命令|
|mkdir|(dirpath:String)|返回创建一个目录及其全部父目录的命令|
|install|(def:Object)|返回安装一个或多个文件的命令|
|symlink|(target:String, linkpath:String)|返回创建符号链接的命令。此操作只有部分系统下有效|

"install"函数的参数为一个对象，描述了一个安装任务，可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|src|String|是|源文件路径|
|srcdir|String|是|源目录路径|
|dst|String|是|目标文件路径|
|dstdir|String|是|目标目录路径|
|mode|String|是|安装后文件的模式，参考"chmod"命令的MODE定义|
|strip|Bool|是|是否对对象文件清除符号信息|

### toolchain
获取工具链对象。

工具链对象包含以下属性：

|属性|类型|描述|
|:-|:-|:-|
|cc|String|C编译器程序名称|
|cxx|String|C++编译器程序名称|
|target|Object|工具链的生成目标平台信息|

目标平台信息对象包含以下属性：

|属性|类型|描述|
|:-|:-|:-|
|name|String|平台名称，如"linux","windows"|
|exe_suffix|String|该平台可执行程序的扩展名|
|slib_suffix|String|该平台静态链接库的扩展名|
|dlib_suffix|String|该平台动态链接库的扩展名|

### Validator对象
用户在扩展中有时需要进行一些检验操作验证当前的一些特性，可以通过继承"Validator"对象实现此类功能。

如用户希望在配置时验证当前环境下Linux内核版本是否大于指定版本：
```
ref "std/shell"

KernelValidator: class Validator {
    //初始化，记录需要的最低版本
    $init(major, minor) {
        this.major = major
        this.minor = minor
    }

    //检测函数
    check() {
        //通过运行命令获取kernel版本号
        out = Shell.output("uname -r")
        m = out.match(/(\d+)\.(\d+)/)

        //解析主次版本号
        major = Number(m.groups[1])
        minor = Number(m.groups[2])

        //如小于最低版本，返回null
        if major < this.major {
            return
        } elif major == this.major {
            if minor < this.minor {
                return
            }
        }

        //测试通过，返回一个实际字符串
        return out
    }

    //获取对象对应字符串。此函数用于打印日志和创建验证器对应的标签
    $to_str() {
        return "kernel {this.major}.{this.minor}"
    }
}
```
在用户的"lrbuild.ox"中可以调用这个类验证内核版本：
```
//创建一个kernel验证对象，最低版本为5.4
kernel = KernelValidator(5, 4)

//验证kernel版本
if !kernel.valid {
    //验证失败退出
    failed("kernel version < 5.4")
} else {
    //验证成功，打印实际版本号。"value"属性对应"check"方法的返回值。
    stdout.puts("kernel: {kernel.value}")
}
```
或者用户可以直接通过以下方法验证：
```
//创建一个kernel验证对象，最低版本为5.4
kernel = KernelValidator(5, 4)

//验证kernel版本, kernel版本小于5.4时直接报错退出
kernel.assert()
```
用户继承"Validator"对象实现自定义验证器的核心是实现"check"方法，在方法中进行相关验证，如果验证失败返回null。如果验证成功
返回一个非null值。在后面的程序中可以通过"value"属性访问这个返回值。

"Validator"对象会记录测试结果，当"lrbuild.ox"文件中多次调用验证器的"valid"方法时，"Validator"会返回第一次的测试结果。

当"lordrabbit"运行结束时，会将所有验证器的测试结果记录到输出目录的"lrcache.ox"文件中。当再次运行"lordrabbit"进行配置时，
"lordrabbit"会先尝试从"lrcache.ox"文件中获取缓存的测试结果，以此来优化运行时间。
如果用户希望不要读取缓存，重新进行全部验证，请在"lordrabbit"运行时加入选项"--nocache"。
## lordrabbit选项
"lordrabbit"程序支持以下选项：

|选项|参数|说明|
|:-|:-|:-|
|-D|MACRO[=VALUE]|增加一个全局宏定义|
|-I|DIR|增加一个全局头文件查找目录|
|-L|DIR|增加一个全局库文件查找目录|
|--cflags|FLAGS|设置全局编译器标记|
|-d|DIR|设置输出目录|
|-f|make|设置输出文件格式。目前只支持"make"(GNU make的Makefile)|
|-g|无|编译产物带调试信息|
|--help|无|显示帮助信息|
|--instdir|DIR|设置安装目录|
|-l|LIB|增加一个全局链接库|
|--ldflags|FLAGS|设置全局链接器标识|
|--listopt|无|列出当前项目的全部选项|
|--nocache|无|不使用缓存文件，重新进行检测|
|-o|FILE|设置输出文件名|
|-s|NAME[=VALUE]|设置一个当前项目的选项|
|--toolchain|gnu\|gnu-clang|设置使用的工具链。当前支持GNU+GCC和GNU+clang|
|--xprefix|PREFIX|设置交叉编译工具链前缀。如设置"--xprefix i686-w64-mingw32"选择MinGW64 交叉编译工具链|

## Makefile参数
"lordrabbit"生成的"Makefile"支持以下参数，可以在运行"make"命令时进行设置：

|参数|说明|
|:-|:-|
|Q|缺省为"Q=@"表示安静模式，需要打开中间打印信息时设置"Q="|
|INST|修改安装目录|

## Makefile目标
"lordrabbit"生成的"Makefile"包含以下特殊目标，可以通过"make 目标"实现一些特殊操作：

|参数|说明|
|:-|:-|
|all|缺省目标，生成所有"lrbuild.ox"中指定需要安装的产物及其依赖文件|
|install|将"lrbuild.ox"中定义的所有需要安装文件安装到安装目录下|
|uninstall|从安装目录下清除已安装的文件|
|clean|清除输出目录下所有创建的产物及中间文件|
|cleanout|清除整个输出目录|

