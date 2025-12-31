module vending_machine(
    input        clk,
    input        reset,                // active-low reset
    input  [7:0] coin,                 // 1, 5, 10, 50
    input  [2:0] drink_choose,          // 0:none, 1~4 drinks
    output reg [7:0] total_money,
    output reg [2:0] state,             // S0~S3
    output reg [7:0] exchange,
    output reg [7:0] drink_out
);

    // --------------------
    // price definition
    // --------------------
    parameter PRICE_TEA    = 8'd10;
    parameter PRICE_COKE   = 8'd15;
    parameter PRICE_COFFEE = 8'd20;
    parameter PRICE_MILK   = 8'd25;

    // --------------------
    // FSM states
    // --------------------
    parameter S0 = 3'd0; // insert coin
    parameter S1 = 3'd1; // select drink
    parameter S2 = 3'd2; // dispense
    parameter S3 = 3'd3; // change

    reg [7:0] current_cost;
    reg [2:0] selected_drink;

    always @(posedge clk or reset) begin
        if (!reset) begin
            // ---------- reset all ----------
            state           <= S0;
            total_money     <= 8'd0;
            exchange        <= 8'd0;
            drink_out       <= 8'd0;
            current_cost    <= 8'd0;
            selected_drink  <= 3'd0;
        end else begin
            case (state)

                // ==================================================
                // S0 : insert coin only
                // ==================================================
                S0: begin
                    drink_out <= 8'd0;
                    exchange  <= 8'd0;

                    if (coin != 8'd0)
                        total_money <= total_money + coin;

                    if ((total_money + coin) >= PRICE_TEA)
                        state <= S1;
                    else
                        state <= S0;
                end

                // ==================================================
                // S1 : select drink only
                // (if coin comes in, eat coin then go back to S0)
                // ==================================================
                S1: begin
                    if (coin != 8'd0) begin
                        // IMPORTANT: coin must be accumulated
                        total_money <= total_money + coin;
                        state <= S0;
                    end
                    else if (drink_choose == 3'd1 && total_money >= PRICE_TEA) begin
                        current_cost   <= PRICE_TEA;
                        selected_drink <= 3'd1;
                        state <= S2;
                    end
                    else if (drink_choose == 3'd2 && total_money >= PRICE_COKE) begin
                        current_cost   <= PRICE_COKE;
                        selected_drink <= 3'd2;
                        state <= S2;
                    end
                    else if (drink_choose == 3'd3 && total_money >= PRICE_COFFEE) begin
                        current_cost   <= PRICE_COFFEE;
                        selected_drink <= 3'd3;
                        state <= S2;
                    end
                    else if (drink_choose == 3'd4 && total_money >= PRICE_MILK) begin
                        current_cost   <= PRICE_MILK;
                        selected_drink <= 3'd4;
                        state <= S2;
                    end
                    else begin
                        state <= S1;
                    end
                end

                // ==================================================
                // S2 : dispense drink (1 cycle)
                // ==================================================
                S2: begin
                    drink_out <= selected_drink;
                    state <= S3;
                end

                // ==================================================
                // S3 : change / checkout
                // ==================================================
                S3: begin
                    exchange <= total_money - current_cost;

                    total_money    <= 8'd0;
                    drink_out      <= 8'd0;
                    current_cost   <= 8'd0;
                    selected_drink <= 3'd0;

                    state <= S0;
                end

                default: state <= S0;
            endcase
        end
    end

endmodule
