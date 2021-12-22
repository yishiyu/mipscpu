# MIPSCPU

西安交大计算机组成大作业

本项目一共有两个 cpu  
先介绍食用方法,再逐个介绍

## 0. 项目食用方法

### 环境安装

首先需要保证环境中安装了 iverilog 和 gtkwave 两个软件  
windows 下需要自己下载并安装  
linux 下可以使用以下命令安装

```
sudo apt-get install iverilog
```

如果以上命令没有成功安装 gtkwave,可以试试下一条命令

```
sudo apt-get install gtkwave
```

在以项目所在文件夹为工作目录,使用以下命令即可运行  
(注意这个 make 其实是 windows 中的批处理文件,在 linux 下运行参照该文件写一个就好了)

```
make testbench
```

### 数据初始化

以字符表示二进制指令,存放在预定义的文件中  
为了解决从汇编到字符二进制指令的转换问题,欢迎去看同名 github pages 网站中的一个小汇编器哈哈哈哈  
(其实非常简陋,只支持简单的指令转换,不支持数据定义和各种伪操作什么的)

[bibibi's website | 简易 mips 汇编器](https://yishiyu.github.io/2019/12/25/%E7%AE%80%E6%98%93mips%E6%B1%87%E7%BC%96%E5%99%A8/)

1. 基于通用寄存器的单总线 CPU  
   指令和数据统一寻址
   指令和数据同时存放在 data.txt 中

2. 五级流水线 CPU  
   指令和数据分开寻址  
   指令存放在 im_data.txt 中  
   数据存放在 dm_data.txt 中

## 1. 基于通用寄存器的单总线 CPU

参考的书为《计算机组成与设计》-清华大学出版社-王换招、陈妍、赵青苹编著

指令格式参考该书第 384 页

数据通路参考该书第 407 页

控制器设计参考该书 408 页

详见同名 github pages 网站 :-D

[bibibi's website | 基于通用寄存器的单总线 CPU](<https://yishiyu.github.io/2020/01/02/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BB%84%E6%88%90%E5%AE%9E%E9%AA%8C(%E4%B8%80)/>)

## 2. 五级流水线 CPU

参考书籍为《Digital Design and Computer Architecture》David Money Harris & Sarah L. Harris 编著
(中文名:数字设计和计算机体系结构)

数据通路和冲突解决两部分参照了该书第 7 章第 5 节

详见同名 github pages 网站 :-D

[bibibi's website | 基于流水线的 CPU](<https://yishiyu.github.io/2020/01/08/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BB%84%E6%88%90%E5%AE%9E%E9%AA%8C(%E4%BA%8C)/>)
