`timescale 1ns/1ps

module stimulus;

    reg        clk;
    reg        reset;
    reg [7:0]  coin;
    reg [2:0]  drink_choose;

    wire [7:0] total_money;
    wire [2:0] state;
    wire [7:0] exchange;
    wire [7:0] drink_out;

    vending_machine vm (
        .clk(clk),
        .reset(reset),
        .coin(coin),
        .drink_choose(drink_choose),
        .total_money(total_money),
        .state(state),
        .exchange(exchange),
        .drink_out(drink_out)
    );

    // clock: 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 依 total_money 自動印出可買飲料（不固定）
    task print_coin_line;
        input [7:0] coin_in;
        input [7:0] total_in;
        reg printed_any;
        begin
            $write("coin %0d, total %0d dollars    ", coin_in, total_in);

            printed_any = 0;

            if (total_in >= 8'd10) begin
                $write("tea");
                printed_any = 1;
            end
            if (total_in >= 8'd15) begin
                if (printed_any) $write(" | ");
                $write("coke");
                printed_any = 1;
            end
            if (total_in >= 8'd20) begin
                if (printed_any) $write(" | ");
                $write("coffee");
                printed_any = 1;
            end
            if (total_in >= 8'd25) begin
                if (printed_any) $write(" | ");
                $write("milk");
                printed_any = 1;
            end

            $write("\n");
        end
    endtask

    initial begin
        // init
        coin = 0;
        drink_choose = 0;
        reset = 0;

        // release reset
        #12 reset = 1;

        // ----- 投幣 10 -----
        coin = 8'd10;
        @(posedge clk); #1;   // << 關鍵：等 nonblocking 更新完
        print_coin_line(coin, total_money);

        // ----- 投幣 5 -----
        coin = 8'd5;
        @(posedge clk); #1;
        print_coin_line(coin, total_money);

        // ----- 投幣 1 -----
        coin = 8'd1;
        @(posedge clk); #1;
        print_coin_line(coin, total_money);

        // ----- 投幣 10 -----
        coin = 8'd10;
        @(posedge clk); #1;
        print_coin_line(coin, total_money);

        // stop coin
        coin = 8'd0;
        @(posedge clk); #1;

        // ----- 選 coffee -----
        drink_choose = 3'd3;
        @(posedge clk); #1;
        $display("coffee out");

        // release choose
        drink_choose = 3'd0;

        // 等到交易結束：S3 做完會回到 S0，且 exchange 已經被更新
        wait (state == 3'd0);
        #1;
        $display("exchange %0d dollars", exchange);

        $finish;
    end

endmodule
