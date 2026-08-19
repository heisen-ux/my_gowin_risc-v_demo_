// ============================================================
// key_debounce.v - 按键消抖模块
//   功能：对低电平有效的按键输入做同步 + 消抖，
//         在“按下”瞬间(下降沿稳定后)输出一个时钟周期的高脉冲。
//   参数：DEB_CNT = 消抖计数阈值（约 10ms @27MHz = 270000）
// ============================================================

module key_debounce (
    input        clk,        // 系统时钟 27MHz
    input        rst_n,      // 复位，低有效
    input        key_in,     // 按键输入（按下=0）
    output       key_press   // 按下瞬间输出 1 拍高脉冲
);

    parameter DEB_CNT = 20'd270000;   // 10ms @27MHz

    reg        key_sync0;
    reg        key_sync1;
    reg [19:0] cnt;
    reg        key_stable;
    reg        key_stable_prev;

    // 两级同步，消除亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync0 <= 1'b1;
            key_sync1 <= 1'b1;
        end else begin
            key_sync0 <= key_in;
            key_sync1 <= key_sync0;
        end
    end

    // 消抖：电平需连续稳定 DEB_CNT 拍才更新稳定值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt        <= 20'd0;
            key_stable <= 1'b1;          // 复位后默认“松开”
        end else begin
            if (key_sync1 != key_stable) begin
                if (cnt < DEB_CNT)
                    cnt <= cnt + 1'b1;
                else begin
                    key_stable <= key_sync1;
                    cnt        <= 20'd0;
                end
            end else begin
                cnt <= 20'd0;
            end
        end
    end

    // 记录上一拍稳定值，用于边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_stable_prev <= 1'b1;
        else
            key_stable_prev <= key_stable;
    end

    // 下降沿（按下）检测：稳定值由 1 -> 0
    assign key_press = (~key_stable) & key_stable_prev;

endmodule
