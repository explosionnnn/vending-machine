module vending_machine(
    input clk,
    input reset,
    input [7:0] coin,          // 直接當金額：1,5,10,50
    input [2:0] drink_choose,  // 001=tea,010=coke,011=coffee,100=milk
    output reg [7:0] total_money,
    output reg [2:0] state,
    output reg [7:0] exchange,
    output reg [2:0] drink_out
);

localparam S0 = 3'b000, //投錢
           S1 = 3'b001, //選飲料
           S2 = 3'b010; //找零 & 回到 S0

// 價格表
function [7:0] price;
input [2:0] drink;
begin
    case(drink)
        3'b001: price = 8'd10; // tea
        3'b010: price = 8'd15; // coke
        3'b011: price = 8'd20; // coffee
        3'b100: price = 8'd25; // milk
        default: price = 8'd0;
    endcase
end
endfunction

// coin 脈衝偵測
reg [7:0] last_coin;
always @(posedge clk or posedge reset)
    if (reset) last_coin <= 0;
    else       last_coin <= coin;

wire coin_valid = (coin != 0) && (last_coin == 0);

// 狀態暫存器
reg [2:0] next_state;

always @(posedge clk or posedge reset) begin
    if (reset)
        state <= S0;
    else
        state <= next_state;
end

// next_state 邏輯
always @(*) begin
    case (state)
        S0: begin
            if (coin_valid && (total_money + coin >= 10))
                next_state = S1;       // 有錢可買至少一種飲料
            else
                next_state = S0;
        end

        S1: begin
            if (drink_choose != 0 && total_money >= price(drink_choose))
                next_state = S2;       // 夠錢且已選飲料 → 出貨/找零
            else if (drink_choose != 0 && total_money < price(drink_choose))
                next_state = S0;       // 錢不夠 → 回去 S0 繼續投
            else
                next_state = S1;       // 等待選飲料
        end

        S2: next_state = S0;           // 出貨/找零後回 S0

        default: next_state = S0;
    endcase
end

// money / output 一個 block 處理（避免多重驅動）
always @(posedge clk or posedge reset) begin
    if (reset) begin
        total_money <= 0;
        exchange    <= 0;
        drink_out   <= 0;
    end else begin
        case (state)
            S0: begin
                exchange  <= 0;
                drink_out <= 0;
                if (coin_valid) begin
                    total_money <= total_money + coin;

                    // 顯示可買飲料
                    $display("-----------------------------");
                    $display("Total money = %0d", total_money + coin);
                    $display("可購買:");
                    if (total_money + coin >= 10) $display("  tea (10)");
                    if (total_money + coin >= 15) $display("  coke (15)");
                    if (total_money + coin >= 20) $display("  coffee (20)");
                    if (total_money + coin >= 25) $display("  milk (25)");
                    $display("-----------------------------");
                end
            end

            S1: begin
                if (drink_choose != 0 && total_money >= price(drink_choose)) begin
                    drink_out   <= drink_choose;                    // 出貨哪一種
                    total_money <= total_money - price(drink_choose); // 扣掉價格
                end
            end

            S2: begin
                exchange    <= total_money; // 剩下的當找零
                total_money <= 0;
            end

            default: begin
                // 可以保持上一值或清零，看你老師要求
            end
        endcase
    end
end

endmodule
