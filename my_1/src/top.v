// ============================================================
// top.v - Tang Nano 9K 片上 SOPC 系统顶层
//
// SOPC 组成：Gowin_PicoRV32 IP(CPU+ITCM/DTCM+中断控制器)
//            + WBGPIO(流水灯/方波) + WBUART(串口)
//            + CPU 内置定时器(方波节拍) + 外部中断(按键)
//
// 四种功能：
//   1) 流水灯   : WBGPIO bit[5:0] -> 板载 6 个 LED（低电平点亮）
//   2) 按键中断 : S1 按键(pin4) -> 消抖 -> irq_in[20]（外部中断）
//   3) 产生方波 : CPU 定时器中断翻转 GPIO bit[6] -> pin22 输出约 1kHz 方波
//   4) 串口通信 : WBUART <-> 板载 CH552 <-> USB 串口(115200)
//
// 使用前需在 Gowin IDE 中用 IP Core Generator 生成：
//   - Gowin_PicoRV32（关键配置见工程说明，必须勾选 Open Wishbone Interface
//     以获得 irq_in[31:20] 外部中断端口，GPIO 宽度=7）
//   - Gowin_rPLL（CLKIN=27MHz, CLKOUT=27MHz）
// ============================================================

module top (
    input         sys_clk,      // 板载 27MHz 时钟
    input         reset_n,      // 复位按键 S2(pin3)，低有效
    output        uart_tx,      // WBUART TX -> CH552 -> USB 串口
    input         uart_rx,      // WBUART RX <- CH552 <- USB 串口
    inout  [6:0]  gpio_io,      // bit[5:0]=LED, bit[6]=方波输出
    input         key           // 按键 S1(pin4)，低有效 -> 外部中断 irq_in[20]
);

// ------------------------------------------------------------
// 1. PLL：27MHz -> 27MHz，提供干净的系统时钟与锁定信号
// ------------------------------------------------------------
wire clk_sys;
wire locked;

Gowin_rPLL u_pll (
    .clkout(clk_sys),
    .lock  (locked),
    .clkin (sys_clk)
);

// ------------------------------------------------------------
// 2. 系统复位：外部复位按键 & PLL 锁定
// ------------------------------------------------------------
wire sys_rst_n;
assign sys_rst_n = reset_n & locked;

// ------------------------------------------------------------
// 3. 按键消抖 -> 外部中断脉冲（S1 按下产生 1 拍高脉冲）
// ------------------------------------------------------------
wire key_irq;

key_debounce u_key_deb (
    .clk       (clk_sys),
    .rst_n     (sys_rst_n),
    .key_in    (key),
    .key_press (key_irq)
);

// ------------------------------------------------------------
// 4. Gowin_PicoRV32 SOPC IP
//    启用 Open Wishbone 接口后，IP 才输出 irq_in[31:20]
// ------------------------------------------------------------
// Open Wishbone 从端口（本设计未挂载从设备，做立即应答）
wire        slv_ext_stb_o, slv_ext_we_o, slv_ext_cyc_o, slv_ext_ack_i;
wire [31:0] slv_ext_adr_o, slv_ext_wdata_o, slv_ext_rdata_i;
wire [3:0]  slv_ext_sel_o;

assign slv_ext_ack_i   = slv_ext_stb_o & slv_ext_cyc_o;   // 立即应答，防止总线挂死
assign slv_ext_rdata_i = 32'h0000_0000;

Gowin_PicoRV32_Top u_sopc (
    .wbuart_tx      (uart_tx),
    .wbuart_rx      (uart_rx),
    .gpio_io        (gpio_io),            // [6:0]
    .slv_ext_stb_o  (slv_ext_stb_o),
    .slv_ext_we_o   (slv_ext_we_o),
    .slv_ext_cyc_o  (slv_ext_cyc_o),
    .slv_ext_ack_i  (slv_ext_ack_i),
    .slv_ext_adr_o  (slv_ext_adr_o),
    .slv_ext_wdata_o(slv_ext_wdata_o),
    .slv_ext_rdata_i(slv_ext_rdata_i),
    .slv_ext_sel_o  (slv_ext_sel_o),
    .irq_in         ({11'b0, key_irq}),  // irq_in[31:20]：bit20 = 按键中断
    .jtag_TDI       (1'b1),               // JTAG 调试口未使用，固定电平
    .jtag_TDO       (),
    .jtag_TCK       (1'b0),
    .jtag_TMS       (1'b1),
    .clk_in         (clk_sys),
    .resetn_in      (sys_rst_n)
);

endmodule
