# ============================================================
# sim.do - ModelSim 仿真脚本
# 目标：Gowin PicoRV32 SOPC（Tang Nano 9K / GW1NR-9）
#
# 使用前提：
#   1) 已用新固件 Debug/ram32.hex 在 Gowin IDE 中重新生成 PicoRV32 IP
#      （IP 网表内的 INIT 参数必须包含新固件指令）
#   2) 工程结构（相对本 sim/ 目录）：
#      ../../src/top.v
#      ../../src/key_debounce.v
#      ../../src/gowin_picorv32/gowin_picorv32.v   （Gowin IDE 生成）
#      ../../src/gowin_rpll/gowin_rpll.v          （Gowin IDE 生成）
#
# 运行方式（在 sim/ 目录下）：
#   命令行：  vsim -do sim.do
#   或 GUI：  启动 ModelSim 后在 Transcript 中执行  do sim.do
# ============================================================

# Gowin 原语仿真库路径（GW1N 系列 = Tang Nano 9K）
quietly set GOWIN_SIMLIB "F:/gowin/Gowin_V1.9.12.03_x64/IDE/simlib/gw1n"

# ---------- 清理并新建工作库 ----------
catch { vdel -all }
vlib work

# ---------- 1. Gowin 原语仿真库（LUT/DFF/RAM/PLL/IOBUF/GSR ...） ----------
vlog -work work "$GOWIN_SIMLIB/prim_sim.v"

# ---------- 2. Gowin IP 网表（PicoRV32 SOPC + rPLL） ----------
vlog -work work ../../src/gowin_picorv32/gowin_picorv32.v
vlog -work work ../../src/gowin_rpll/gowin_rpll.v

# ---------- 3. 用户 RTL ----------
vlog -work work ../../src/top.v
vlog -work work ../../src/key_debounce.v

# ---------- 4. Testbench ----------
vlog -work work tb_top.v

# ---------- 5. 启动仿真 ----------
vsim -t 1ps work.tb_top

# ---------- 6. 波形窗口 ----------
add wave -divider "SOPC Top"
add wave -radix binary  /tb_top/u_top/sys_clk
add wave -radix binary  /tb_top/u_top/reset_n
add wave -radix binary  /tb_top/u_top/key
add wave -radix binary  /tb_top/u_top/uart_tx
add wave -radix binary  /tb_top/u_top/uart_rx
add wave -radix binary  /tb_top/u_top/gpio_io
add wave -divider "Check"
add wave /tb_top/sq_toggle_cnt

# ---------- 7. 运行（由 tb 中的 $finish / 300ms 超时结束） ----------
run -all
