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

    reg [63:0] multiplicand;  // 被乘数寄存器

    // 被乘数左移控制
    always @ (posedge clk) begin
        if (judge) begin              // 运算过程中，被乘数每次左移一位
            multiplicand <= {multiplicand[62:0],1'b0};
        end
        else if (start_i) begin       // 开始时，加载操作数
            multiplicand <= {32'd0,op1_absolute};
        end
    end

    // 乘数右移控制
    always @ (posedge clk) begin
        if(judge) begin               // 运算过程中，乘数每次右移一位
            multiplier <= {1'b0,multiplier[31:1]};
        end
        else if(start_i) begin        // 开始时，加载操作数
            multiplier <= op2_absolute;
        end
    end

    // 根据乘数最低位决定是否需要加上部分积
    assign temporary_value = multiplier[0] ? multiplicand : 64'd0;

    // 累加部分积
    always @ (posedge clk) begin
        if (judge) begin              // 运算过程中，累加部分积
            mul_temporary <= mul_temporary + temporary_value;
        end
        else if (start_i) begin       // 开始时，清零累积结果
            mul_temporary <= 64'd0;
        end
    end

    // 确定最终结果的符号
    always @ (posedge clk) begin
        if (judge) begin              // 运算过程中，根据输入操作数的符号确定结果符号
            result_sign <= op1_sign ^ op2_sign;
        end
    end

    // 根据符号位决定是否需要对结果取补
    assign result_o = result_sign ? (~mul_temporary+1) : mul_temporary;
    // 当乘数为0时，表示运算完成
    assign ready_o = judge & multiplier == 32'b0;

endmodule