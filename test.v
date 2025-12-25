module vending_machine(
    input clk,
    input reset,                // Negative edge triggered
    input [7:0] coin,           // Coin input: 1, 5, 10, 50
    input [2:0] drink_choose,   // 0=None, 1=Tea, 2=Coke, 3=Coffee, 4=Milk
    output reg [7:0] total_money, // Accumulated money
    output reg [2:0] state,       // Current FSM state
    output reg [7:0] exchange,    // Change to return
    output reg [7:0] drink_out    // Drink output ID 
);

    parameter PRICE_TEA    = 8'd10;
    parameter PRICE_COKE   = 8'd15;
    parameter PRICE_COFFEE = 8'd20;
    parameter PRICE_MILK   = 8'd25;

    parameter S0 = 3'd0; // Initial/Accumulate
    parameter S1 = 3'd1; // Selection
    parameter S2 = 3'd2; // Dispense
    parameter S3 = 3'd3; // Checkout/Change

    reg [7:0] current_cost;
    reg [2:0] prev_drink_choose;

    function [8*6-1:0] drinkdisplay;
        input [2:0] drink_choose;
        case (drink_choose)
            3'd1: drinkdisplay = "Tea";
            3'd2: drinkdisplay = "Coke";
            3'd3: drinkdisplay = "Coffee";
            3'd4: drinkdisplay = "Milk";
            default: drinkdisplay = "None";
        endcase
    endfunction

    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            state <= S3;
        end
        else begin
            case (state)
                // --------------------------------------------------------
                // S0: Initial State 
                // --------------------------------------------------------
                S0: begin
                    exchange  <= 8'd0; 
                    drink_out <= 8'd0; 
                    if (coin > 0) begin
                        total_money <= total_money + coin; 
                        $display("Input Coin: %d, Total: %d", coin, total_money + coin);
                    end
                    
                    if ((total_money + coin) >= PRICE_TEA) begin
                        state <= S1;
                    end
                    else begin
                        state <= S0;
                    end
                end

                // --------------------------------------------------------
                // S1: Selection State 
                // --------------------------------------------------------
                S1: begin
                    if (coin > 0) begin
                        total_money <= total_money + coin;
                    end
 
                    if (drink_choose == 3'd1 && total_money >= PRICE_TEA) begin
                        state <= S2;
                        current_cost <= PRICE_TEA;
                        prev_drink_choose <= 3'd1;
                    end
                    else if (drink_choose == 3'd2 && total_money >= PRICE_COKE) begin
                        state <= S2;
                        current_cost <= PRICE_COKE;
                        prev_drink_choose <= 3'd2;
                    end
                    else if (drink_choose == 3'd3 && total_money >= PRICE_COFFEE) begin
                        state <= S2;
                        current_cost <= PRICE_COFFEE;
                        prev_drink_choose <= 3'd3;
                    end
                    else if (drink_choose == 3'd4 && total_money >= PRICE_MILK) begin
                        state <= S2;
                        current_cost <= PRICE_MILK;
                        prev_drink_choose <= 3'd4;
                    end
                    else begin
                        state <= S1; 
                    end
                    $display("Money: %d", total_money);
                    $display("Selected Drink: %s, Cost: %d", drinkdisplay(drink_choose), current_cost);
                end

                // --------------------------------------------------------
                // S2: Dispense State 
                // --------------------------------------------------------
                S2: begin
                    drink_out <= {5'd0, prev_drink_choose};
                    state <= S3; 
                    $display("Dispensing Drink: %s", drinkdisplay(prev_drink_choose));
                end

                // --------------------------------------------------------
                // S3: Checkout State 
                // --------------------------------------------------------
                S3: begin
                    state <= S0;  
                    exchange <= total_money - current_cost;           
                    total_money <= 8'd0;     
                    drink_out <= 8'd0;
                    current_cost <= 8'd0;
                    prev_drink_choose <= 3'd0;
                    $display("Returning Change: %d", exchange);
                end
                
                default: state <= S0;
            endcase
        end
    end

endmodule
