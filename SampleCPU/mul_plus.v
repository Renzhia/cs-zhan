// 设置时间尺度：时间单位1ns，时间精度1ps
`timescale 1ns / 1ps 

// 乘法器模块定义
module mul_plus(
    input clk,             // 时钟信号
    input start_i,         // 乘法启动信号
    input mul_sign,        // 乘法符号控制：1表示有符号乘法，0表示无符号乘法
    input [31:0] opdata1_i,// 第一个操作数
    input [31:0] opdata2_i,// 第二个操作数
    output [63:0] result_o,// 乘法结果
    output ready_o         // 结果就绪信号
);

    reg judge;             // 乘法运算状态标志
    reg [31:0] multiplier; // 乘数寄存器
    wire [63:0] temporary_value; // 部分积
    reg [63:0] mul_temporary;    // 累积结果
    reg result_sign;       // 结果符号位

    // 控制乘法运算状态
    always @(posedge clk) begin
        if (!start_i || ready_o) begin // 未开始或已完成时
            judge <= 1'b0;
        end
        else begin                     // 运算进行中
            judge <= 1'b1;
        end
    end

    // 处理操作数的符号
    wire op1_sign;         // 第一个操作数的符号
    wire op2_sign;         // 第二个操作数的符号
    wire [31:0] op1_absolute; // 第一个操作数的绝对值
    wire [31:0] op2_absolute; // 第二个操作数的绝对值

    // 根据mul_sign确定是否需要考虑操作数符号
    assign op1_sign = mul_sign & opdata1_i[31];
    assign op2_sign = mul_sign & opdata2_i[31];
    // 计算操作数的绝对值
    assign op1_absolute = op1_sign ? (~opdata1_i+1) : opdata1_i;
    assign op2_absolute = op2_sign ? (~opdata2_i+1) : opdata2_i;



endmodule