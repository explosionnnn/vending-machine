module vending_machine(
    input clk,
    input reset,
    input [7:0] coin,          // 1,5,10,50
    input [2:0] drink_choose,  // 001=tea,010=coke,011=coffee,100=milk
    output reg [7:0] total_money,
    output reg [2:0] state,
    output reg [7:0] exchange,
    output reg [7:0] drink_out
);

// State definition
localparam S0 = 3'b000, // Insert Coin
           S1 = 3'b001, // Select Drink
           S2 = 3'b010, // Dispense Drink
           S3 = 3'b011; // Change / Checkout

// Price function
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

// Coin edge detection
reg [7:0] last_coin;
always @(posedge clk or negedge reset)
    if (!reset) last_coin <= 0;
    else        last_coin <= coin;

wire coin_valid = (coin != 0) && (last_coin == 0);

// Next state logic
reg [2:0] next_state;

always @(*) begin
    case (state)
        S0: begin
            if (total_money >= 8'd10)
                next_state = S1;
            else
                next_state = S0;
        end

        S1: begin
            if (coin_valid)
                next_state = S0; // Go back to S0 to handle coin insertion
            else if (drink_choose != 0 && total_money >= price(drink_choose))
                next_state = S2; // Dispense
            else if (total_money < 8'd10)
                next_state = S0; // Should not happen if logic is correct, but safety
            else
                next_state = S1; // Stay in selection
        end

        S2: next_state = S3; // Go to change

        S3: next_state = S0; // Go back to start

        default: next_state = S0;
    endcase
end

// State and Data registers
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        state       <= S3;
        drink_out   <= 0;
    end else begin
        state <= next_state;

        // Logic for data handling
        case (state)
            S0: begin
                exchange  <= 0;
                drink_out <= 0;
                if (coin_valid) begin
                    total_money <= total_money + coin;
                end
            end

            S1: begin
                exchange  <= 0;
                drink_out <= 0;
                if (coin_valid) begin
                    total_money <= total_money + coin; 
                end
                
                if (drink_choose != 0 && total_money >= price(drink_choose) && !coin_valid) begin
                    // Prepare for S2
                    total_money <= total_money - price(drink_choose);
                    drink_out   <= {5'b0, drink_choose}; // Output drink ID
                end
            end

            S2: begin
                // Drink is dispensed (drink_out is valid from S1 transition)
                // Wait for transition to S3
            end

            S3: begin
                drink_out <= 0;
                exchange    <= total_money;
                total_money <= 0;
            end
        endcase
    end
end

endmodule
