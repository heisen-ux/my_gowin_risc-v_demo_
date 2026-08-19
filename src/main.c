/*
 ******************************************************************************************
 * @file		main.c
 * @brief		Tang Nano 9K + Gowin PicoRV32 片上 SOPC 系统
 *
 *              功能1 流水灯   —— WBGPIO bit[5:0] 驱动板载 6 个 LED（低电平点亮）
 *              功能2 按键中断 —— S1 按键触发外部中断 IRQ20，切换流水灯方向
 *              功能3 产生方波 —— CPU 定时器中断(IRQ0)翻转 GPIO bit[6]，输出约 1kHz 方波
 *              功能4 串口通信 —— WBUART @115200：接收回显 + 状态信息输出
 *
 *              说明：仅修改本文件即可，其余库函数(bsp/lib)保持不变；
 *                    硬件配套见 hardware/picorv32_sopc 工程。
 ******************************************************************************************
 */

#include "config.h"
#include "picorv32.h"
#include "firmware.h"
#include "irq.h"
#include "wbuart.h"
#include "wbgpio.h"

/* 中断标志：由 bsp/irq.c 的 ISR 置位，主循环轮询处理 */
uint8_t irq00_flag = 0;		// IRQ0   定时器中断
uint8_t irq13_flag = 0;		// IRQ13  WBUART 接收中断
uint8_t irq20_flag = 0;		// IRQ20  按键外部中断
uint8_t irq21_flag = 0;		// IRQ21  保留（本设计未使用）

/* GPIO 位分配（硬件 IP 的 Gpio_Data_Width = 7） */
#define GPIO_LED_MASK    (0x0000003FUL)	/* bit[5:0] -> 6 个 LED，低电平点亮 */
#define GPIO_SQWAVE_BIT  (6)			/* bit[6]   -> 方波输出 */

/* 方波半周期定时器计数值：SYSCLKFREQ/2000 = 13500 个时钟(0.5ms)，
 * 每次定时器中断翻转一次 -> 方波周期 1ms，频率约 1kHz。
 * 若实测频率偏差，直接调整该值即可。 */
#define SQ_WAVE_HALF_PERIOD  (SYSCLKFREQ / 2000)

/* 流水灯节奏：每 400 个定时器节拍（0.5ms * 400 = 200ms）移动一位 */
#define FLOW_STEP_TICKS      (400)

static uint8_t  g_flow_dir = 1;		/* 1: 左移  0: 右移 */
static uint8_t  g_flow_pos = 0;		/* 当前点亮的 LED 位 */
static uint32_t g_gpio_out = 0;		/* 当前 GPIO 输出值 */
static uint32_t g_tick     = 0;		/* 定时器节拍计数 */

/* 将 g_gpio_out 写入 GPIO 寄存器 */
static void gpio_flush(void)
{
	GPIO_WriteData(PICO_WBGPIO, g_gpio_out);
}

/* 流水灯前进一步 */
static void led_flow_step(void)
{
	if (g_flow_dir)
		g_flow_pos = (g_flow_pos + 1) % 6;		/* 左移 */
	else
		g_flow_pos = (g_flow_pos + 5) % 6;		/* 右移（减 1） */

	/* LED 低电平点亮：bit 为 1 表示熄灭 */
	g_gpio_out = (g_gpio_out & ~GPIO_LED_MASK)
	           | ((~(1UL << g_flow_pos)) & GPIO_LED_MASK);
	gpio_flush();
}

/* 翻转方波输出位 */
static void square_wave_toggle(void)
{
	g_gpio_out ^= (1UL << GPIO_SQWAVE_BIT);
	gpio_flush();
}

/* =================== 主函数 =================== */
int main(void)
{
	/* 1. 关闭所有中断，初始化外设 */
	mask_irq(0xFFFFFFFF);
	wbuart_init(115200);				/* WBUART 115200bps */
	GPIO_Init(PICO_WBGPIO);

	/* 2. GPIO 全部输出：bit[5:0]=LED, bit[6]=方波 */
	GPIO_SetDir(PICO_WBGPIO, 0x7F);
	g_gpio_out = GPIO_LED_MASK;			/* 初始 LED 全灭，方波低电平 */
	gpio_flush();

	printf("\r\n==========================================\r\n");
	printf("Tang Nano 9K PicoRV32 SOPC Demo\r\n");
	printf("System Clock: %d MHz\r\n", SYSCLKFREQ / MHz);
	printf("==========================================\r\n\r\n");

	/* 3. 使能中断 */
	irq_enable_one_bit(0);				/* 定时器中断 */
	irq_enable_one_bit(20);				/* 按键外部中断 */
	irq_enable_one_bit(13);				/* WBUART 接收中断 */
	enable_timer_interrupt();
	enable_external_interrupt();
	enable_interrupt_global();

	/* 4. 启动定时器 -> 产生方波 */
	set_timer(SQ_WAVE_HALF_PERIOD);

	printf("[OK] LED flow running...\r\n");
	printf("[OK] Press S1 key to switch LED direction\r\n");
	printf("[OK] gpio_io[6] outputs ~1kHz square wave\r\n");
	printf("[OK] UART echo enabled, type any char to test\r\n\r\n");

	/* 5. 主循环：非阻塞，轮询中断标志 */
	while (1)
	{
		/* 定时器中断：方波翻转 + 流水灯节拍计数 */
		if (irq00_flag)
		{
			irq00_flag = 0;
			g_tick++;
			square_wave_toggle();
			if ((g_tick % FLOW_STEP_TICKS) == 0)
				led_flow_step();
			irq_enable_one_bit(0);
			set_timer(SQ_WAVE_HALF_PERIOD);	/* 重新装载定时器 */
		}

		/* 按键外部中断：切换流水灯方向 */
		if (irq20_flag)
		{
			irq20_flag = 0;
			g_flow_dir = !g_flow_dir;
			printf("[INT] Key pressed! LED direction -> %s\r\n",
			       g_flow_dir ? "LEFT" : "RIGHT");
			irq_enable_one_bit(20);
		}

		/* WBUART 接收中断：读取并回显 */
		if (irq13_flag)
		{
			irq13_flag = 0;
			uint8_t ch = wbuart_getc();
			printf("RX: 0x%02X '%c'\r\n", ch,
			       (ch >= 32 && ch <= 126) ? ch : '.');
			irq_enable_one_bit(13);
		}
	}

	return 0;
}
