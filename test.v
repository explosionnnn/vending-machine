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

    // ==========================================
    // Parameter Definitions 
    // ==========================================
    // Drink Prices
    parameter PRICE_TEA    = 8'd10;
    parameter PRICE_COKE   = 8'd15;
    parameter PRICE_COFFEE = 8'd20;
    parameter PRICE_MILK   = 8'd25;

    // FSM States
    parameter S0 = 3'd0; // Initial/Accumulate
    parameter S1 = 3'd1; // Selection
    parameter S2 = 3'd2; // Dispense
    parameter S3 = 3'd3; // Checkout/Change

    // Internal register to store the cost of the selected drink for calculation
    reg [7:0] current_cost;

    // ==========================================
    // FSM Sequential Logic
    // ==========================================
    // Triggered on positive edge clk or negative edge reset
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // Reset behavior: Return to S0, exit all entered coins 
            state       <= S0;
            exchange    <= total_money; // Refund current money
            total_money <= 8'd0;
            drink_out   <= 8'd0;
            current_cost<= 8'd0;
        end
        else begin
            // Default signal clearing
            exchange  <= 8'd0; 
            drink_out <= 8'd0; 

            case (state)
                // --------------------------------------------------------
                // S0: Initial State 
                // --------------------------------------------------------
                S0: begin
                    // Accept coins
                    if (coin > 0) begin
                        total_money <= total_money + coin; 
                    end
                    
                    // If money is enough for the cheapest drink (10), move to Selection 
                    // Note: We check total_money + coin to transition immediately if coin makes it >= 10
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
                    // Still accept coins in this state
                    if (coin > 0) begin
                        total_money <= total_money + coin;
                    end

                    // Check for Drink Selection
                    // Logic: Check if selection is made AND money is sufficient 
                    if (drink_choose == 3'd1 && total_money >= PRICE_TEA) begin
                        state <= S2;
                        current_cost <= PRICE_TEA;
                        drink_out <= 3'd1; // Output Tea ID
                    end
                    else if (drink_choose == 3'd2 && total_money >= PRICE_COKE) begin
                        state <= S2;
                        current_cost <= PRICE_COKE;
                        drink_out <= 3'd2; // Output Coke ID
                    end
                    else if (drink_choose == 3'd3 && total_money >= PRICE_COFFEE) begin
                        state <= S2;
                        current_cost <= PRICE_COFFEE;
                        drink_out <= 3'd3; // Output Coffee ID
                    end
                    else if (drink_choose == 3'd4 && total_money >= PRICE_MILK) begin
                        state <= S2;
                        current_cost <= PRICE_MILK;
                        drink_out <= 3'd4; // Output Milk ID
                    end
                    else begin
                        state <= S1; // Stay in selection if no valid choice/funds
                    end
                end

                // --------------------------------------------------------
                // S2: Dispense State 
                // --------------------------------------------------------
                S2: begin
                    // Drink output was set in the transition from S1 to ensure it holds
                    // We maintain the drink_out signal for this cycle
                    // You might need to re-assign drink_out here depending on waveform requirements
                    // but usually, setting it in the transition is sufficient.
                    
                    // Move immediately to checkout
                    state <= S3; 
                end

                // --------------------------------------------------------
                // S3: Checkout State 
                // --------------------------------------------------------
                S3: begin
                    // Calculate change
                    exchange <= total_money - current_cost;
                    
                    // Clear money for next customer
                    total_money <= 8'd0;
                    
                    // Return to Initial State
                    state <= S0;
                end
                
                default: state <= S0;
            endcase
        end
    end

endmodule
