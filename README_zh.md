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

CC   out/intermediate/test-exe-test.o <- test.c
EXE  out/bin/test <- out/intermediate/test-exe-test.o
```
可以看到在"out/bin"目录下编译生成了可执行程序"test"。
## 基本概念
### lrbuild.ox
"lrbuild.ox"是客户编写的配置和构建描述文件。"lordrabbit"程序会加载当前目录下的"lrbuild.ox"文件，
根据文件描述进行配置并生成"Makefile"文件。

"lrbuild.ox"是一个用[OX语言](https://gitee.com/gongke1978/ox)编写的脚本。
脚本开头通过引用语句引用了"lordrabbit"软件包：
```
ref "lordrabbit"
```
脚本后面通过调用"lordrabbit"提供的函数，描述了项目的配置和构建方法。
### 输出目录
构建生成的文件会放置到输出目录中，缺省的输出目录为当前目录下的"out"子目录。

"lordrabbit"程序可以通过选项"-o"修改输出目录。
### 中间文件目录
构建过程中会生成一些中间文件，如".o",".dep"文件，这些文件会放置到输出目录下的"intermediate"子目录中。
### 安装目录
运行"make install"命令，可以将构建产物安装到系统中。安装目录为产物安装的根目录。
如安装目录为"/usr/local",可执行程序会安装到"/usr/local/bin"目录下，库文件会安装到"/usr/local/lib"目录下。

缺省的安装目录为"/usr"，"lordrabbit"程序可以通过选项"--instdir"修改安装目录。
在进行"make install"时也可以通过设置参数"INST"修改安装目录：
```
make install INST=/home/zhangsan
```
### 工具链
工具链是编译器/链接器等一系列编译相关工具的集合。"lordrabbit"目前支持两种工具链：

* gnu: GNU gcc/g++/ld等工具
* gnu-clang: 使用GNU工具链，但编译器使用clang和clang++

## 函数
"lordrabbit"提供了一组函数用于帮助用户配置和构建项目。
### build_exe
构建一个可执行程序。

函数参数为一个对象，描述了可执行程序的构建方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|可执行程序的名称|
|srcs|[String]|否|源文件列表|
|incdirs|[String]|是|头文件查找目录|
|macros|[String]|是|通过命令行定义的宏|
|libdirs|[String]|是|库查找目录|
|libs|[String]|是|可执行程序需要链接的库|
|cflags|String|是|编译器标记|
|ldflags|String|是|链接器标记|
|pcs|[String]|是|可执行程序需要通过"pkg-config"链接的模块|
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
gcc -c -o out/intermediate/test-exe-test.o test.c -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
生成以下命令链接创建可执行程序"test":
```
gcc -o out/bin/test out/intermediate/test-exe-test.o -L/usr/lib/ext -lext -lm -ldl -flto
```
注意可执行程序名称不要包含扩展名部分，"lordrabbit"会根据生成目标平台自动添加扩展名。
如可执行程序名为"test"，"lordrabbit"在linux下会生成可执行程序文件"test"，windows下会生成可执行程序文件"test.exe"。

"srcs"定义了源文件数组，每一个源文件表示为相对路径名。如果源文件字符串以"+"开头，表示相对路径是以输出目录为根目录。
如果源文件字符串以"-"开头，表示相对路径是以中间文件目录为根目录。如：
```
build_exe({
    name: "test"
    srcs: [
        "test.c"          //"./test.c"
        "+generated.c"    //"out/generated.c"
        "-intermediate.c" //"out/intermediate/intermediate.c"
    ]
})
```
"libs"定义链接库数组，每一个链接库名称不要包含"lib"前缀和扩展名。如可执行程序需要链接"libm.so", 库名称应写为"m"。

"pcs"表示可执行程序依赖"pkg-config"中的模块。"lordrabbit"会通过运行"pkg-config"程序获取模块对应的编译器标识和链接器标识。
模块字符串格式为"模块名:版本号"，冒号前为"pkg-config"模块名，冒号后为需要的模块最低版本号。如果没有":版本号"部分，
"lordrabbit"不会检测模块的版本。

"instdir"表示可执行程序的安装子目录名。当运行"make install"时，生成的可执行程序被安装到安装目录的这个子目录下。
如果没有设置"instdir"，默认为子目录为"bin"。如果"instdir"设置为"none"，表示这个可执行程序不需要安装。

"incdirs"和"libdirs"表示头文件查找目录和库文件查找目录。如果目录字符串以"+"开头，表示字符串是以输出目录为根目录的目录名。
如果目录字符串以"-"开头，表示字符串是以中间文件目录为根目录的目录名。
### build_lib
构建一个库文件。

函数参数为一个对象，描述了库的构建方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|库名称|
|srcs|[String]|否|源文件列表|
|incdirs|[String]|是|头文件查找目录|
|macros|[String]|是|通过命令行定义的宏|
|libdirs|[String]|是|库查找目录|
|libs|[String]|是|需要链接的库|
|cflags|String|是|编译器标记|
|ldflags|String|是|链接器标记|
|pcs|[String]|是|库需要通过"pkg-config"链接的模块|
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
在生成的"Makefile"中，会生成以下命令编译对象文件"test-exe-test.o":
```
gcc -c -o out/intermediate/test-lib-test.o test.c -fPIC -I/usr/include/ext -DENABLE_TEST -DVERSION=1 -Wall -O2 -flto
```
生成以下命令创建动态链接库：
```
gcc -o out/lib/libtest.so out/intermediate/test-lib-test.o -shared -L/usr/lib/ext -lext -lm -ldl -flto
```
生成以下命令创建静态链接库：
```
ar rcs out/lib/libtest.a out/intermediate/test-lib-test.o
ranlib out/lib/libtest.a
```
注意库名称不要包含"lib"前缀和扩展名部分，"lordrabbit"会自动添加补全库文件名称。

"srcs"定义了源文件数组，每一个源文件表示为相对路径名。如果源文件字符串以"+"开头，表示相对路径是以输出目录为根目录。
如果源文件字符串以"-"开头，表示相对路径是以中间文件目录为根目录。

"libs"定义的链接库数组，每一个链接库名称不要包含"lib"前缀和扩展名。如可执行程序需要链接"libm.so", 库名称应写为"m"。

"pcs"表示库依赖"pkg-config"中的模块。"lordrabbit"会通过运行"pkg-config"程序获取模块对应的编译器标识和链接器标识。
模块字符串格式为"模块名:版本号"，冒号前为"pkg-config"模块名，冒号后为需要的模块最低版本号。如果没有":版本号"部分，
"lordrabbit"不会检测模块的版本。

"instdir"表示库文件的安装子目录名。当运行"make install"时，生成的库文件被安装到安装目录的这个子目录下。
如果没有设置"instdir"，默认为子目录为"lib"。如果"instdir"设置为"none"，表示这个库文件不需要安装。

"incdirs"和"libdirs"表示头文件查找目录和库文件查找目录。如果目录字符串以"+"开头，表示字符串是以输出目录为根目录的目录名。
如果目录字符串以"-"开头，表示字符串是以中间文件目录为根目录的目录名。

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
在linux下，上面的描述生成的动态链接库名为"libtest.so.1"，同时链接器增加选项指定soname为"libtest.so.1"。
同时"lordrabbit"创建一个符号链接"libtest.so"指向"libtest.so.1"。

在windows下，上面的描述生成的动态链接库名为"libtest-1.dll"。

"lordrabbit"会同时生成静态链接库和动态链接库。如果用户只想生成动态链接库，可使用函数"build_dlib"。
如果用户只想生成静态链接库，可使用函数"build_slib"。
### gen_file
使用工具生成一个文件。

函数参数为一个对象，描述了文件的生成方法。参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|name|String|否|生成文件名称|
|srcs|[String]|是|源文件列表|
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
"srcs"属性指定了生成目标文件依赖的源文件。如果源文件字符串以"+"开头，表示相对路径是以输出目录为根目录。
如果源文件字符串以"-"开头，表示相对路径是以中间文件目录为根目录。

"cmd"属性指定了生成文件的命令。其中可以加入一些特殊标记：

|标记|说明|
|:-|:-|
|$@|生成文件名|
|$<|首个源文件名|
|$^|全部源文件名，以空格分隔|
|$N|N为十进制数，表示第N个源文件名|
|$$|替换为"$"|

"instdir"表示生成文件的安装子目录名。设置"instdir"属性后，生成文件放置在输出目录下。
当运行"make install"时，生成的库文件被安装到安装目录的子目录下。
如果没有设置"instdir"，或"instdir"设置为"none"，表示这个库文件不需要安装，此时生成文件放置在中间文件目录下。
### install
指定需要额外安装的文件。

函数参数为一个对象，参数对象可以包含以下属性：

|属性|类型|可选|描述|
|:-|:-|:-|:-|
|srcs|[String]|是|需要安装文件列表|
|instdir|String|否|文件的安装目录|

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
### subdirs
加载子目录下的"lrbuild.ox"。

一个工程可以划分为多个子模块，每个子模块放在一个子目录下，在每个子目录下可以用一个独立的"lrbuild.ox"描述子模块的配置和构建方法。
"subdirs"函数用来加载子目录下的"lrbuild.ox"文件。

"subdirs"参数为一个数组，表示包含"lrbuild.ox"文件的所有子目录。如：
```
subdirs([
    "sub1"
    "sub2"
])
```
上面的描述加载"sub1/lrbuild.ox"和"sub2/lrbuild.ox"两个子模块描述。
### define
增加一个全局宏定义。

函数参数为一个字符串，表示要增加的宏定义。

如：
```
define("ENABLE_TEST")
define("CONFIG_VALUE=1978")
```
以上声明在生成的Makefile中，每个编译".o"的命令都增加了"-DENABLE_TEST -DCONFIG_VALUE=1978"的标记。
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
### add_incdir
增加一个全局头文件查找目录。

函数参数为一个字符串,表示新增的头文件查找目录。

如：
```
add_incdir("/usr/include/SDL")
```
在生成的Makefile中，编译".o"的命令中增加了"-I/usr/include/SDL"的标记。
### add_libdir
增加一个全局库文件查找目录。

函数参数为一个字符串,表示新增的库文件查找目录。

如：
```
add_libdir("/home/zhangsan/lib")
```
在生成的Makefile中，链接命令中增加了"-L/home/zhangsan/lib"的标记。
### add_lib
增加一个全局链接库。

函数参数为一个字符串,表示新增的库名称。

如：
```
add_lib("pthread")
add_lib("m")
```
在生成的Makefile中，链接命令中增加了"-lpthread -lm"的标记。
### add_cflags
增加全局编译器标记。

函数参数为一个字符串,表示新增的编译器标记。

如：
```
add_cflags("-Wall")
add_cflags("-O2")
```
在生成的Makefile中，编译".o"的命令中增加了"-Wall -O2"标记。
### add_ldflags
增加全局链接器标记。

函数参数为一个字符串,表示新增的链接器标记。

如：
```
add_ldflags("-flto")
```
在生成的Makefile中，链接命令中增加了"-flto"标记。
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
### failed
报错退出配置过程。

如：
```
failed("error!")
```
执行到此语句时，"lordrabbit"会抛出异常并退出。
### have_h
检查当前环境下是否能找到需要的头文件。"lordrabbit"会尝试使用工具链测试包含该头文件是否可以编译成功。
当前的全局"incdirs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示头文件名称
* 对象：表示头文件测试环境设置，包含以下属性：
    - name: 头文件名称
    - cflags：测试时的编译标识
    - incdirs: 测试时的头文件查找目录
    - macros: 测试时的宏定义
    - pcs: 测试依赖的pkg-config模块
    - cxx: 是否用C++编译器进行测试

函数返回布尔值，表示头文件是否可以找到。

如：
```
//检测当前环境"pthread.h"是否可用，如果可用定义宏。
if have_h("pthread.h") {
    define("HAVE_PTHREAD_H")
}
```
### assert_h
检查当前环境下是否可找到需要的头文件，如果找不到报错退出。

如：
```
assert_h("pthread.h") //如"pthread.h"不可用报错退出
```
### have_lib
检查当前环境下是否可以链接需要的库。"lordrabbit"会尝试使用工具链测试链接库是否可以成功。
当前的全局"incdirs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 表示库名称
* 对象：表示测试环境设置，包含以下属性：
    - name: 库名称
    - cflags：测试时的编译标识
    - incdirs: 测试时的头文件查找目录
    - macros: 测试时的宏定义
    - libdirs: 测试时的库查找目录
    - libs：测试时要链接的库
    - ldflags: 测试时的链接器标识
    - pcs: 测试时依赖的pkg-config模块
    - cxx: 是否用C++编译器进行测试

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
### assert_lib
检查当前环境下是否可以链接需要的库,没找到时报错退出。

如：
```
assert_lib("pthread") //验证当前是否有可用的"libpthread"库，没有时报错退出。
```
### have_macro
检查当前环境下是否定义了指定的宏。"lordrabbit"会尝试使用工具链测试宏是否已定义。
当前的全局"incdirs","macros"和"cflags"会被自动用于测试的编译过程。

参数可以为：

* 字符串: 表示宏名称
* 对象：表示宏测试环境设置，包含以下属性：
    - name: 宏名称
    - cflags：测试时的编译标识
    - incdirs: 测试时的头文件查找目录
    - macros: 测试时的宏定义
    - pcs: 测试时依赖的pkg-config模块
    - cxx: 是否用C++编译器进行测试

函数返回布尔值，表示宏是否定义。

如：
```
//通过宏"WIN32"检测目标平台是否为window
if have_macro("WIN32") {
    failed("do not support windows")
}
```
### assert_macro
检查当前环境下是否定义了指定的宏，没有定义时报错退出。

如：
```
assert_macro("__GNUC__") //检验宏"__GNUC__",如果未定义退出
```
### have_func
检验当前环境下是否定义了指定的函数。"lordrabbit"会尝试使用工具链测试函数调用是否可以正常编译链接。
当前的全局"incdirs","macros","cflags","libdirs","libs"和"ldflags"会被自动用于测试过程。

参数可以为：

* 字符串: 函数名称
* 对象：表示测试环境设置，可以包含以下属性：
    - name: 函数名称
    - cflags：测试时的编译标识
    - incdirs: 测试时的头文件查找目录
    - macros: 测试时的宏定义
    - libdirs: 测试时的库查找目录
    - libs：测试时要链接的库
    - ldflags: 测试时的链接器标识
    - pcs: 测试时依赖的pkg-config模块
    - src: 测试源码
    - cxx: 是否用C++编译器进行测试

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
### assert_func
检验当前环境下是否定义了指定的函数,未定义时报错退出。

如：
```
assert_func("printf") //必须定义"printf"函数，否则退出
```
### have_pc
检验"pkg-config"模块是否已安装。"lordrabbit"会尝试通过"pkg-config"工具检验模块是否安装。

参数为一个字符串，其格式为"模块名:版本"，如果":版本"部分不存在，只检测模块是否已安装。如果存在":版本"部分，会检测已安装版本是否大于等于指定的最低版本。

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
### assert_pc
检验"pkg-config"模块是否已安装，未安装时报错退出。

如：
```
//确保"SDL"模块版本>=1.2.68
assert_pc("SDL:1.2.68")
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
### assert_exe
检验可执行程序是否存在,不存在时报错退出。
```
assert_exe("ox") //必须安装可执行程序"ox"
```
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
### config_h
将全局宏定义输出到一个头文件中。

通常配置过程中用户会通过"define"函数定义很多全局宏，"lordrabbit"会将这些宏放在"Makefile"文件中".o"对象编译的命令行中。
如果调用"config_h"函数，这些全局宏定义会写到一个头文件中，而不会出现在"Makefile"文件的命令行中。此时源文件通过包含这个头文件
获取全局宏定义。

通常"config_h"调用应出现在"lrbuild.ox"文件末尾。

参数为一个字符串，标识头文件名称。如果字符串以"+"开始，表示文件在输出目录下。如果字符串以"-"开始，表示文件在中间文件目录下。
如果参数没有给出，缺省文件名为"config.h"。
### package
设置软件包信息。

参数为一个表示软件包信息的对象，包含以下属性:

* name: 软件包名称
* version: 版本号

如:
```
package({
    name: "MyProject"
    version: "0.0.1"
})
```
### gtkdoc
使用"gtkdoc"创建文档。

参数为一个对象,包含以下属性。

* module: 模块名
* srcdir: 源文件目录, gtkdoc会扫描目录下的源文件获取文档信息
* hdrs: 头文件列表，gtkdoc会加载头文件获取文档信息s
* instdir: 安装目录。缺省为"share/doc/gtkdoc-PACKAGE-MODULE"。其中PACKAGE为软件包名，MODULE为模块名
* formats: 输出文档格式列表，可以包含"html","man"或"pdf"。缺省为"html"

如：
```
//为"MyModule"生成文档
gtkdoc({
    module: "MyModule"
    srcdir: "src"
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
|O|修改输出目录|
|INST|修改安装目录|
|CFALGS|添加全局编译器标识|
|LDFALGS|添加全局链接器标识|

## Makefile目标
"lordrabbit"生成的"Makefile"包含以下特殊目标，可以通过"make 目标"实现一些特殊操作：

|参数|说明|
|:-|:-|
|all|缺省目标，生成所有"lrbuild.ox"中指定的需要安装的产物|
|prod|生成需要安装的二进制产物|
|doc|生成文档|
|install|将"lrbuild.ox"中定义的所有需要安装文件安装到安装目录下|
|uninstall|从安装目录下清除已安装的文件|
|clean|清除输出目录下所有"lrbuild.ox"中指定的需要安装的产物|
|cleanall|清除输出目录下所有"lrbuild.ox"中指定的需要安装的产物，生成文件，目标文件及依赖文件|
|cleanout|清除整个输出目录|

