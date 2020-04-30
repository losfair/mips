# 计组实验：单周期 CPU

# 参考资料

- [A single-cycle MIPS processor](https://courses.cs.washington.edu/courses/cse378/09wi/lectures/lec07.pdf)
- [MIPS® Architecture for Programmers Volume II-A: The MIPS32® Instruction Set Manual](https://s3-eu-west-1.amazonaws.com/downloads-mips/documents/MD00086-2B-MIPS32BIS-AFP-6.06.pdf)

# 结构

本项目中，我们：

- 用 iverilog 仿真 Verilog 代码
- 用 GCC 工具链和 Python 脚本生成测试程序
- 用 Makefile 管理构建流程

与课程 PPT 推荐的环境不太一样，但 Verilog 实现部分与 Modelsim 平台并无差异。
