/*
 * tb_top.v - Gowin PicoRV32 SOPC 系统仿真 Testbench（Tang Nano 9K）
 *
 * 验证目标（对应固件四种功能）：
 *   1) 流水灯   ：观察 gpio_io[5:0] 逐位移位
 *   2) 按键中断 ：模拟 S1 按下 50ms，触发 IRQ20 切换方向（串口打印 + 方向变化）
 *   3) 产生方波 ：统计 gpio_io[6] 翻转次数（sq_toggle_cnt）
 *   4) 串口通信 ：模拟 PC 发送 0x41('A')，观察 uart_tx 回显 "RX: 0x41 'A'"
 *
 * 使用方式：
 *   - Gowin IDE 内置仿真(GowinSim)：把本文件加入工程仿真配置，顶层选 tb_top
 *   - ModelSim：在 sim 目录下执行  vsim -do sim.do
 *
 * 注意：仿真前必须先用新固件生成 ram32.hex 并重新生成 PicoRV32 IP，
 *       否则仿真运行的是旧固件（ILM 指令来自 IP 网表内的 INIT）。
 */
`timescale 1ns/1ps

module tb_top;

    /* ---------------- 端口与 DUT ---------------- */
    reg         sys_clk = 1'b0;    // 27MHz 板载时钟
    reg         reset_n = 1'b0;    // 复位（低有效）
    wire        uart_tx;           // WBUART TX（观察回显）
    reg         uart_rx = 1'b1;    // WBUART RX（模拟 PC 发送）
    wire [6:0]  gpio_io;           // bit[5:0]=LED  bit[6]=方波
    reg         key     = 1'b1;    // 按键 S1（低有效）

    top u_top (
        .sys_clk  (sys_clk),
        .reset_n  (reset_n),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx),
        .gpio_io  (gpio_io),
        .key      (key)
    );

    /* ---------------- 27MHz 时钟：半周期 18.518ns ---------------- */
    always #18.518 sys_clk = ~sys_clk;

    /* ---------------- 方波翻转计数器（验证功能3） ---------------- */
    reg     sq_prev = 1'b0;
    integer sq_toggle_cnt = 0;
    always @(posedge sys_clk) begin
        if (gpio_io[6] !== sq_prev) begin
            sq_toggle_cnt = sq_toggle_cnt + 1;
            sq_prev       = gpio_io[6];
        end
    end

    /* ---------------- 模拟串口发送一个字节（115200, LSB first） ---------------- */
    localparam integer UART_BIT_NS = 8680;    // 1/115200s ≈ 8680ns

    task uart_send_byte(input [7:0] d);
        integer i;
        begin
            uart_rx = 1'b0;                   // 起始位
            #UART_BIT_NS;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = d[i];
                #UART_BIT_NS;
            end
            uart_rx = 1'b1;                   // 停止位
            #UART_BIT_NS;
        end
    endtask

    /* ---------------- 主激励 ---------------- */
    initial begin
        $display("[TB] ======== PicoRV32 SOPC Simulation Start ========");

        /* 复位：低电平 200ns 后释放（PLL 锁定后 CPU 才开始运行） */
        $display("[TB] reset assert");
        reset_n = 1'b0;
        #200;
        reset_n = 1'b1;
        $display("[TB] reset release @ %0t ns", $time);

        /* 等待 PLL 锁定 + 系统初始化 + UART 打印启动信息 */
        #5_000_000;
        $display("[TB] boot done @ %0t ns,  sq_toggle_cnt=%0d", $time, sq_toggle_cnt);

        /* 模拟按键 S1 按下 50ms（消抖 10ms 后触发 IRQ20） */
        $display("[TB] press key (S1)...");
        key = 1'b0;
        #50_000_000;
        key = 1'b1;
        $display("[TB] key released @ %0t ns", $time);

        /* 等待按键中断处理（切换流水灯方向 + 串口打印） */
        #5_000_000;

        /* 模拟 PC 串口发送字符 'A' (0x41)，验证回显 */
        $display("[TB] uart send 0x41 ('A') ...");
        uart_send_byte(8'h41);
        $display("[TB] uart sent @ %0t ns", $time);

        /* 继续运行，观察回显与方波 */
        #10_000_000;

        $display("[TB] sim done @ %0t ns,  sq_toggle_cnt=%0d", $time, sq_toggle_cnt);
        $display("[TB] ======== Simulation Finish ========");
        $finish;
    end

    /* ---------------- 总超时保护（300ms） ---------------- */
    initial begin
        #300_000_000;
        $display("[TB] TIMEOUT! stop @ %0t ns", $time);
        $finish;
    end

endmodule
