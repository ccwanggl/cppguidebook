# 开发环境与平台选择

[TOC]

## IDE 不是编译器！

TODO

## 编译器是？

编译器是将源代码 (`.cpp`) 编译成可执行程序 (`.exe`) 的工具。

> {{ icon.fun }} C++ 是**编译型语言**，源代码不能直接执行哦！刚开始学编程的小彭老师曾经把网上的 “Hello, World” 代码拷贝到 `.c` 源码文件中，然后把后缀名改成 `.exe`，发现这样根本执行不了……后来才知道需要通过一种叫做**编译器**编译 `.c` 文件，才能得到计算机可以直接执行的 `.exe` 文件。

C++ 源码 `.cpp` 是写给人类看的！计算机并不认识，计算机只认识二进制的机器码。要把 C++ 源码转换为计算机可以执行的机器码。

## 编译器御三家

最常见的编译器有：GCC、Clang、MSVC

> {{ icon.fun }} 俗称“御三家”。

这些编译器都支持了大部分 C++20 标准和小部分 C++23 标准，而 C++17 标准都是完全支持的。

> {{ icon.fun }} 有人说过：“如果你不知道一个人是用的什么编译器，那么你可以猜他用的是 GCC。”

- GCC 主要只在 Linux 和 MacOS 等 Unix 类系统可用，不支持 Windows 系统。但是 GCC 有着大量好用的扩展功能，例如大名鼎鼎的 `pbds`（基于策略的数据结构），还有各种 `__attribute__`，各种 `__builtin_` 系列函数。不过随着新标准的出台，很多原本属于 GCC 的功能都成了标准的一部分，例如 `__attribute__((warn_unused))` 变成了标准的 `[[nodiscard]]`，`__builtin_clz` 变成了标准的 `std::countl_zero`，`__VA_OPT__` 名字都没变就进了 C++20 标准。

> {{ icon.fun }} PBDS 又称 “平板电视”

- 也有 MinGW 这样的魔改版 GCC 编译器，把 GCC 移植到了 Windows 系统上，同时也能用 GCC 的一些特性。不过 MinGW 最近已经停止更新，最新的 GCC Windows 移植版由 MinGW-w64 继续维护。

- Clang 是跨平台的编译器，支持大多数主流平台，包括操作系统界的御三家：Linux、MacOS、Windows。Clang 支持了很大一部分 GCC 特性和部分 MSVC 特性。其所属的 LLVM 项目更是编译器领域的中流砥柱，不仅支持 C、C++、Objective-C、Fortran 等，Rust 和 Swift 等语言也是基于 LLVM 后端编译的，不仅如此，还有很多显卡厂商的 OpenGL 驱动也是基于 LLVM 实现编译的。并且 Clang 身兼数职，不仅可以编译，还支持静态分析。许多 IDE 常见的语言服务协议 (LSP) 就是基于 Clang 的服务版————Clangd 实现的 (例如你可以按 Ctrl 点击，跳转到函数定义，这样的功能就是 IDE 通过调用 Clangd 的 LSP 接口实现）。不过 Clang 的性能优化比较激进，虽然有助于性能提升，如果你不小心犯了未定义行为，Clang 可能优化出匪夷所思的结果，如果你要实验未定义行为，Clang 是最擅长复现的。且 Clang 对一些 C++ 新标准特性支持相对较慢，没有 GCC 和 MSVC 那么上心。

> {{ icon.story }} 例如 C++20 早已允许 lambda 表达式捕获 structural-binding 变量，而 Clang 至今还没有支持，尽管 Clang 已经支持了很多其他 C++20 特性。

- Apple Clang 是苹果公司自己魔改的 Clang 版本，只在 MacOS 系统上可用，支持 Objective-C 和 Swift 语言。但是版本较官方 Clang 落后一些，很多新特性都没有跟进，基本上只有专门伺候苹果的开发者会用。

> {{ icon.tip }} GCC 和 Clang 也支持 Objective-C。

- MSVC 是 Windows 限定的编译器，提供了很多 MSVC 特有的扩展。也有人在 Clang 上魔改出了 MSVC 兼容模式，兼顾 Clang 特性的同时，支持了 MSVC 的一些特性（例如 `__declspec`），可以编译用了 MSVC 特性的代码，即 `clang-cl`，在最新的 VS2022 IDE 中也集成了 `clang-cl`。值得注意的是，MSVC 的优化能力是比较差的，比 GCC 和 Clang 都差，例如 MSVC 几乎总是假定所有指针 aliasing，这意味着当遇到很多指针操作的循环时，几乎没法做循环矢量化。但是也使得未定义行为不容易产生 Bug，另一方面，这也导致一些只用 MSVC 的人不知道某些写法是未定义行为。

- Intel C++ compiler 是英特尔开发的 C++ 编译器，由于是硬件厂商开发的，特别擅长做性能优化。但由于更新较慢，基本没有更上新特性，也没什么人在用了。

> {{ icon.detail }} 最近他们又出了个 Intel DPC++ compiler，支持最新的并行编程领域特定语言 SyCL。

## 使用编译器编译源码

### MSVC

```bash
cl.exe main.cpp
```

这样就可以得到可执行文件 `main.exe` 了。

### GCC

```bash
g++ main.cpp -o main
```

这样就可以得到可执行文件 `main` 了。

> {{ icon.tip }} Linux 系统的可执行文件并没有后缀名，所以没有 `.exe` 后缀。

### Clang

Windows 上：

```bash
clang++.exe main.cpp -o main.exe
```

Linux / MacOS 上：

```bash
clang++ main.cpp -o main
```

## 编译器选项

编译器选项是用来控制编译器的行为的。不同的编译器有不同的选项，语法有微妙的不同，但大致功效相同。

例如当我们说“编译这个源码时，我用了 GCC 编译器，`-O3` 和 `-std=c++20` 选项”，说的就是把这些选项加到了 `g++` 的命令行参数中：

```bash
g++ -O3 -std=c++20 main.cpp -o main
```

其中 Clang 和 GCC 的编译器选项有很大交集。而 MSVC 基本自成一派。

Clang 和 GCC 的选项都是 `-xxx` 的形式，MSVC 的选项是 `/xxx` 的形式。

常见的编译器选项有：

### C++ 标准

指定要选用的 C++ 标准。

Clang 和 GCC：`-std=c++98`、`-std=c++03`、`-std=c++11`、`-std=c++14`、`-std=c++17`、`-std=c++20`、`-std=c++23`

MSVC：`/std:c++98`、`/std:c++11`、`/std:c++14`、`/std:c++17`、`/std:c++20`、`/std:c++latest`

例如要编译一个 C++20 源码文件，分别用 GCC、Clang、MSVC：

GCC（Linux）：

```bash
g++ -std=c++20 main.cpp -o main
```

Clang（Linux）：

```bash
clang++ -std=c++20 main.cpp -o main
```

MSVC（Windows）：

```bash
cl.exe /std:c++20 /c main.cpp
```

### 优化等级

Clang 和 GCC：`-O0`、`-O1`、`-O2`、`-O3`、`-Ofast`、`-Os`、`-Oz`、`-Og`

- `-O0`：不进行任何优化，编译速度最快，忠实复刻你写的代码，未定义行为不容易产生诡异的结果，一般用于开发人员内部调试阶段。
- `-O1`：最基本的优化，会把一些简单的死代码（编译器检测到的不可抵达代码）删除，去掉没有用的变量，把部分变量用寄存器代替等，编译速度较快，执行速度也比 `-O0` 快。但是会丢失函数的行号信息，影响诸如 gdb 等调试，如需快速调试可以用 `-Og` 选项。
- `-O2`：比 `-O1` 更强的优化，会把一些循环展开，把一些函数内联，减少函数调用，把一些简单的数组操作用更快的指令替代等，执行速度更快。
- `-O3`：比 `-O2` 更激进的优化，会把一些复杂的循环用 SIMD 矢量指令优化加速，把一些复杂的数组操作用更快的指令替代等。性能提升很大，但是如果你的程序有未定义行为，可能会导致一些 Bug。如果你的代码没有未定义行为则绝不会有问题，对自己的代码质量有自信就可以放心开，编译速度也会很慢，一般用于程序最终成品发布阶段。
- `-Ofast`：在 `-O3` 的基础上，进一步对浮点数的运算进行更深层次的优化，但是可能会导致一些浮点数计算结果不准确。如果你的代码不涉及到 NaN 和 Inf 的处理，那么 `-Ofast` 不会有太大的问题，一般用于科学计算领域的终极性能优化。
- `-Os`：在 `-O2` 的基础上，专门优化代码大小，性能被当作次要需求，但是会禁止会导致可执行文件变大的优化。会把一些循环展开、内联等优化关闭，把一些代码用更小的指令实现，尽可能减小可执行文件的尺寸，比 `-O0`、`-O1`、`-O2` 都要小，通常用于需要节省内存的嵌入式系统开发。
- `-Oz`：在 `-Os` 的基础上，进一步把代码压缩，可能把本可以一条大指令完成的任务也拆成多条小指令，为了缩小尺寸牺牲运行时性能，大幅减少了函数内联的机会，有时用于嵌入式系统开发。
- `-Og`：在 `-O0` 的基础上，尽可能保留更多调试信息，不做破坏函数行号等信息的优化，建议配合产生更多调试信息的 `-g` 选项使用。但还是会做一些简单的优化，比 `-O0` 执行速度更快。但 `-Og` 的所有优化都不会涉及到未定义行为，因此非常适合调试未定义行为。但是由于插入了调试信息，最终的可执行文件会变得很大，一般在开发人员调试时使用。

MSVC：`/Od`、`/O1`、`/O2`、`/Ox`、`/Ob1`、`/Ob2`、`/Os`

- `/Od`：不进行任何优化，忠实复刻你写的代码，未定义行为不容易产生诡异的结果，一般用于调试阶段。
- `/O1`：最基本的优化，会把一些简单的死代码删除，去掉没有用的变量，把变量用寄存器代替等。
- `/O2`：比 `/O1` 更强的优化，会把一些循环展开，把一些函数内联，减少函数调用，还会尝试把一些循环矢量化，把一些简单的数组操作用更快的指令替代等。一般用于发布阶段。
- `/Ox`：在 `/O2` 的基础上，进一步优化，但是不会导致未定义行为，一般用于发布阶段。
- `/Ob1`：启用函数内联。
- `/Ob2`：启用函数内联，但是会扩大内联范围，一般比 `/Ob1` 更快，但是也会导致可执行文件变大。
- `/Os`：在 `/O2` 的基础上，专门优化代码大小，性能被当作次要需求，但是会禁止会导致可执行文件变大的优化。会把一些循环展开、内联等优化关闭，把一些代码用更小的指令实现，尽可能减小可执行文件的尺寸，通常用于需要节省内存的嵌入式系统开发。

> {{ icon.detail }} 注意：函数内联是一种优化策略，和 `inline` 关键字毫无关系，请看稍后推出的符号链接专题课程或抢先看[小彭老师视频](https://www.bilibili.com/video/BV1Mg4y1d79w)了解 `inline`，以后的性能优化专题课程也会介绍函数内联优化的成功案例。

### 调试信息

Clang 和 GCC：`-g`、`-g0`、`-g1`、`-g2`、`-g3`

MSVC：`/Z7`、`/Zi`

### 头文件搜索路径

### 指定要链接的库

### 库文件搜索路径

### 定义宏

Clang 和 GCC：`-Dmacro=value`

MSVC：`/Dmacro=value`

例如：

### 警告开关

## 标准库御三家

- libstdc++ 是 GCC 官方的 C++ 标准库实现，由于 GCC 是 Linux 系统的主流编译器，所以 libstdc++ 也是 Linux 上最常用的标准库。你可以在这里看到他的源码：https://github.com/gcc-mirror/gcc/tree/master/libstdc%2B%2B-v3

- libc++ 是 Clang 官方编写的 C++ 标准库实现，由于 Clang 是 MacOS 系统的主流编译器，所以 libc++ 也是 MacOS 上最常用的标准库。libc++ 也是 C++ 标准库中最早实现 C++11 标准的。项目的开源地址是：https://github.com/llvm/llvm-project/tree/main/libcxx

- MSVC STL 是 MSVC 官方的 C++ 标准库实现，由于 MSVC 是 Windows 系统的主流编译器，所以 MSVC STL 也是 Windows 上最常用的标准库。MSVC STL 也是 C++ 标准库中最晚实现 C++11 标准的，但是现在他已经完全支持 C++20，并且也完全开源了：https://github.com/microsoft/STL

值得注意的是，标准库和编译器并不是绑定的，例如 Clang 可以用 libstdc++ 或 MSVC STL，GCC 也可以被配置使用 libc++。

在 Linux 系统中，Clang 默认用的就是 libstdc++。需要为 Clang 指定 `-stdlib=libc++` 选项，才能使用。

> {{ icon.fun }} 牛头人笑话：“如果你不知道一个人是用的什么标准库，那么你可以猜他用的是 libstdc++。因为即使他的编译器是 Clang，他用的大概率依然是 libstdc++。”

### 标准库的调试模式

不少标准库都有提供

#### GCC 开启标准库调试模式

如果你用的是 GCC 默认的 libstdc++ 库，可以定义宏 `#define _GLIBCXX_DEBUG` 以开启调试模式，此模式下会帮助检测标准库用法上出现的未定义行为，例如尝试解引用 `end()` 迭代器时，会抛出错误信息，帮助你检查代码中有没有未定义行为。

也可以通过命令行选项 `-D_GLIBCXX_DEBUG` 开启。

在 CMake 中添加以下选项，即可对特定目标程序启用标准库调试模式：

```cmake
target_compile_definitions(你的程序 PRIVATE _GLIBCXX_DEBUG)
```

> {{ icon.fun }} 有的人会老老实实的复制粘贴，连“你的程序”都忘记改成你真正的程序名。

在 CMakeLists.txt 最前面加上可以对所有接下来的目标启用：

```cmake
add_compile_definitions(_GLIBCXX_DEBUG)

add_executable(你的程序1)  # 示例
add_executable(你的程序2)  # 示例
```

注意：

开启此选项后，如果你的 exe 程序链接了其他用 C++ 写的库，那么这些库也必须开启调试模式！否则 ABI 会出现不兼容，导致奔溃。这是因为  `_GLIBCXX_DEBUG` 开启后，会改变 C++ 容器的布局和大小（为了调试而塞入的额外帮手变量导致容器结构与开启前不同），链接其他用 C 语言写的库不会有问题，因为此宏仅会影响标准库中 C++ 的部分。

开启标准库调试模式后，因为需要做很多参数安全性检查，性能会受损，建议仅在调试环节启用！等你调试完消除了未定义行为后，在最终发布的版本中中关闭，恢复正常性能。

你可以通过判定 `CMAKE_BUILD_TYPE` 是否等于 `Debug`，实现只在 Debug 模式下启用标准库安全检查。

```cmake
if (CMAKE_BUILD_TYPE MATCHES "[Dd][Ee][Bb][Uu][Gg]")
    add_compile_definitions(-D_GLIBCXX_DEBUG)
endif()
```

#### MSVC 的标准库调试模式

MSVC 有两个“config”，其中 Debug config 就是标准库调试模式，会帮助你检查迭代器越界等常见未定义行为。

### 警告选项

#### GCC 建议开启的警告选项

建议初学者开启以下选项，可以避免很多常见错误写法，改善你的代码质量：

```
-Wall -Wextra -Weffc++
-Werror=uninitialized
-Werror=return-type
-Wconversion -Wsign-compare
-Werror=unused-result
-Werror=suggest-override
-Wzero-as-null-pointer-constant
-Wmissing-declarations
-Wold-style-cast -Werror=vla
-Wnon-virtual-dtor
```

视频介绍：https://www.bilibili.com/video/BV1qT421a7zj

### C++11 ABI 问题

在一些特别古老的发行版上（比如 Ubuntu 16.04、CentOS），他们的标准库不支持 C++11，可以开启这个宏：

```cpp
#define _GLIBCXX_USE_CXX11_ABI 0
```

或者命令行选项 `-D_GLIBCXX_USE_CXX11_ABI=0`。

由于 Linux 发行版大多会捆绑特定 GCC 版本（往往是很低的版本！），为了更好的学习现代 C++，我建议：

1. 安装新的 Linux 发行版，最好是 Arch Linux，Tumbleweed 这类**滚动更新**的发行版，它们的所有包永久保持最新。
2. 自己从源码编译 Clang，LLVM 团队打造优秀的代码品质使得 Clang 对系统底层解耦，不像 GCC 那么难伺候环境依赖。
3. 或者使用 Wendous 等可以自由安装最新版 MSVC 的系统。
