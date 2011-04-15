====================
 Autotools 实例分析
====================

简介
~~~~

autotools 的主要目的是方便用户, 简化软件编译的步骤。用 autotools 搭建的软件都可
以这样来编译::

    $ ./configure
    $ make
    $ sudo make install

用户不需要去自己检查系统配置, 软件的依赖, 安装路径。这三步已经成为 Linux (以及
其他 UNIX 系统) 上编译软件的标准命令, 其他编译系统 (比如 cmake, scons, python
的 setup.py) 尽管有各自的好处, 但反而不容易被用户接受。

下面以 xwininfo 为例, 分析一下 autotools 的使用。xwininfo 是一个很简单的软件,
只为用户提供两个文件::

    $ conary q xwininfo --ls
    /usr/share/man/man1/xwininfo.1.gz
    /usr/bin/xwininfo

在 /usr/bin 目录下安装了一个可执行程序, 然后在 /usr/share 目录下安装了一个手册。

xwininfo 的源代码树
~~~~~~~~~~~~~~~~~~~

下边看一下 xwininfo 的源代码。

编译完成之后的目录树::

    build/xwininfo-1.1.1/xwininfo-1.1.1/
    |-- COPYING
    |-- ChangeLog
    |-- INSTALL
    |-- Makefile
    |-- Makefile.am
    |-- Makefile.in
    |-- README
    |-- aclocal.m4
    |-- autogen.sh
    |-- autom4te.cache
    |   |-- output.0
    |   |-- output.1
    |   |-- output.2
    |   |-- requests
    |   |-- traces.0
    |   |-- traces.1
    |   `-- traces.2
    |-- clientwin.c
    |-- clientwin.h
    |-- clientwin.o
    |-- config.guess
    |-- config.h
    |-- config.h.in
    |-- config.h.in~
    |-- config.log
    |-- config.status
    |-- config.sub
    |-- configure
    |-- configure.ac
    |-- depcomp
    |-- dsimple.c
    |-- dsimple.h
    |-- dsimple.o
    |-- install-sh
    |-- m4
    |-- missing
    |-- stamp-h1
    |-- strnlen.c
    |-- strnlen.h
    |-- strnlen.o
    |-- xwininfo
    |-- xwininfo.1
    |-- xwininfo.c
    |-- xwininfo.man
    `-- xwininfo.o

    2 directories, 43 files

一共有 2 个目录 (其中 m4 是一个空目录), 43 个文件。

再看从 tar 包 (layers/wrll-userspace/graphics/packages/xwininfo-1.1.1.tar.bz2)
解压出来的目录树::

    .
    |-- COPYING
    |-- ChangeLog
    |-- INSTALL
    |-- Makefile.am
    |-- Makefile.in
    |-- README
    |-- aclocal.m4
    |-- autogen.sh
    |-- clientwin.c
    |-- clientwin.h
    |-- config.guess
    |-- config.h.in
    |-- config.sub
    |-- configure
    |-- configure.ac
    |-- depcomp
    |-- dsimple.c
    |-- dsimple.h
    |-- install-sh
    |-- missing
    |-- strnlen.c
    |-- strnlen.h
    |-- xwininfo.c
    `-- xwininfo.man

    0 directories, 24 files

只有 24 个文件。

再看 `git 仓库`_ 中的目录树 (也就是开发者进行开发的目录树)::

    .
    |-- autogen.sh
    |-- clientwin.c
    |-- clientwin.h
    |-- configure.ac
    |-- COPYING
    |-- dsimple.c
    |-- dsimple.h
    |-- Makefile.am
    |-- README
    |-- strnlen.c
    |-- strnlen.h
    |-- xwininfo.c
    `-- xwininfo.man

    0 directories, 13 files

.. _git 仓库: http://cgit.freedesktop.org/xorg/app/xwininfo/

只有 13 个文件。显然, tar 包里包含一些生成的文件, 而在用户执行 ./configure 和
make 的时候, 又生成了一些文件。

xwininfo 的编译系统
~~~~~~~~~~~~~~~~~~~

我们可以把 git 仓库中的 13 个文件分一下类。

代码文件
    clientwin.c  clientwin.h  dsimple.c  dsimple.h  strnlen.c  strnlen.h
    xwininfo.c
文档
    COPYING  README  xwininfo.man
编译系统
    autogen.sh  configure.ac  Makefile.am

代码和文档可算作一个项目真正“有意义”的东西, 除此之外的其他文件只有三个。它们也
就是 xwininfo 的编译系统。

什么是 autotools?
~~~~~~~~~~~~~~~~~

autotools 指的是:

- autoconf - 生成 configure 文件 (configure.ac -> configure)
- automake - 生成 Makefile 模板 (Makefile.am -> Makefile.in) (XXX)
- libtool - 生成共享库

.. image:: images/autoconf.svg

上图解释了一个软件从 git 仓库到安装到用户系统上的过程。过程的参与者有两个, 开发
者和用户。

autotools (autoconf 和 automake) 是给开发者用的, 用户在编译软件时, 不需要安装
autotools。用户要执行的命令是：

configure
    由 autoconf 生成
make
    在用户系统上安装。Makefile 是由 configure 从 Makefile.in 生成的。

autoconf
~~~~~~~~

Autoconf 是 autotools 套件中被最早开发出来的 (1991 年)。它解决的问题包括：

- 找到系统上的库和头文件
- 软件编好后安到合适的路径
- 正确选择软件的组件和功能点

Autoconf 提供的可执行程序包括：

1. autoconf
#. autom4te
#. autoreconf
#. autoheader
#. autoscan

autoconf
--------

autoconf 是一个简单的 .sh 脚本。主要功能是检查当前 shell 能否支持 M4 的处理。然
后在对命令行参数进行简单解析后, 转给 autom4te::

    $ tail -n6 /usr/bin/autoconf
    # Run autom4te with expansion.
    eval set x "$autom4te_options" \
      --language=autoconf --output=\"\$outfile\" "$traces" \"\$infile\"
    shift
    $verbose && $as_echo "$as_me: running $AUTOM4TE $*" >&2
    exec "$AUTOM4TE" "$@"

autom4te
--------

autom4te 是对 m4 的一个封装, 它能够利用缓存来提高速度。我们经常能看到这样一个缓
存目录::

    $ ls autom4te.cache/
    output.0  output.1  output.2  requests  traces.0  traces.1  traces.2

从 configure.ac 到 configure 的转换, 本质上是由 m4 完成的。这个转换过程无非就是
m4 宏定义的递归扩展。

autoreconf
----------

autoreconf 可以看作是所有 autotools 的封装, 它能够根据 configure.ac 正确调
用其他的工具, 最终生成 configure 脚本。

autoheader
----------

autoheader 能够根据 configure.ac 生成一个头文件的模板, 一般叫做 config.h.in 。
里边一般包换对项目组件和各种特性的开关(也就是宏定义)::

    $ head config.h.in
    /* config.h.in.  Generated from configure.ac by autoheader.  */

    /* Define to 1 if you have the iconv() function */
    #undef HAVE_ICONV

    /* Define to 1 if you have the <inttypes.h> header file. */
    #undef HAVE_INTTYPES_H

    /* Define to 1 if you have the <memory.h> header file. */
    #undef HAVE_MEMORY_H

用户执行 configure 后, 会从 config.h.in 生成 config.h, 其中的宏定义根据用户系统
的实际情况被替换为了真实数值::

    $ head config.h
    /* config.h.  Generated from config.h.in by configure.  */
    /* config.h.in.  Generated from configure.ac by autoheader.  */

    /* Define to 1 if you have the iconv() function */
    #define HAVE_ICONV 1

    /* Define to 1 if you have the <inttypes.h> header file. */
    #define HAVE_INTTYPES_H 1

    /* Define to 1 if you have the <memory.h> header file. */

对于 autotools, 模板文件都以 .in 做为后缀, 比如 config.h.in, Makefile.in。模板
文件由 configure 处理成最终文件.

autoscan
--------
autoscan 能够扫描项目源代码，自动生成 configure.ac。

automake
~~~~~~~~

在 automake 出现之前，人们必须手写 Makefile。但是项目稍微有点规模后，Makefile
就很容易变得又长又臭, 很难维护。但是有这样一个事实，大多数项目在结构上都是类似
的。无论项目的代码文件里有什么，都是在一个递归的代码树里面，并且一般都要支持这
些常见的 make 操作::

    $ make
    $ make clean
    $ make check
    $ make dist
    ....

Automake 能够简化 Makefile 的维护，自动生成可移植的 Makefile。

Automake 提供两个可执行程序:

1. automake
#. aclocal

automake
--------

aclocal
-------
