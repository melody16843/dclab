module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_GET_KEY = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_WAIT = 3;
localparam S_SEND_DATA = 4;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [2:0] state_r, state_w;
logic [4:0] avm_address_r, avm_address_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

logic [2:0] state_count_w, state_count_r;

localparam GET_N = 2'd0;
localparam GET_D = 2'd1;
localparam GET_ENC = 2'd2;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    //default value
    state_count_w = state_count_r;
    state_w = state_r;
    avm_address_w = avm_address_r;
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    dec_w = dec_r;
    bytes_counter_w = bytes_counter_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    rsa_start_w = rsa_start_r;

    //FSM
    case(state_r)
    S_GET_KEY:begin
        //dectect whether rx is ready(avn_waitrequest ==0 && avm_readdata[7] ==1)
        if (!avm_waitrequest) begin
            if(avm_address_r == STATUS_BASE & avm_readdata[7]) begin
                StartRead(RX_BASE);
                state_w = S_GET_DATA;
            end
            else begin
                StartRead(STATUS_BASE);
                state_w = S_GET_KEY;
            end

        end
        else begin
            StartRead(STATUS_BASE);
            state_w = S_GET_KEY;

        end
    end
    S_GET_DATA:begin
        //read data to rignt place
        // n d enc each has 256bit. since readdata only provide 8 bit, we need to load 32 times.
        // decide go to next or not
        case(state_count_r)
        GET_N:begin
            if (!avm_waitrequest) begin
                if(avm_address_r == RX_BASE & bytes_counter_r<7'd31)begin
                    n_w = n_w << 8;
                    n_w[7:0] = avm_readdata[7:0];
                    state_count_w = state_count_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_KEY;
                    StartRead(STATUS_BASE);

                end
                else if(avm_address_r == RX_BASE & bytes_counter_r == 7'd31) begin
                    n_w = n_w << 8;
                    n_w[7:0] = avm_readdata[7:0];
                    state_count_w = GET_D;
                    bytes_counter_w = 7'd0;
                    state_w = S_GET_KEY;
                    StartRead(STATUS_BASE);

                end
            end
        end
        GET_D:begin
            if (!avm_waitrequest) begin
                if(bytes_counter_r<7'd31)begin
                    d_w = d_w << 8;
                    d_w[7:0] = avm_readdata[7:0];
                    state_count_w = state_count_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_KEY;
                    StartRead(STATUS_BASE);

                end
                else begin
                    d_w = d_w << 8;
                    d_w[7:0] = avm_readdata[7:0];
                    state_count_w = GET_ENC;
                    bytes_counter_w = 7'd0;
                    state_w = S_GET_KEY;
                    StartRead(STATUS_BASE);

                end
            end
        end
        GET_ENC:begin
            if (!avm_waitrequest) begin
                if(bytes_counter_r<7'd31)begin
                    enc_w = enc_w << 8;
                    enc_w[7:0] = avm_readdata[7:0];
                    state_count_w = GET_ENC;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_KEY;
                    StartRead(STATUS_BASE);

                end
                else begin
                    enc_w = enc_w << 8;
                    enc_w[7:0] = avm_readdata[7:0];
                    state_count_w = GET_ENC;
                    bytes_counter_w = 7'd0;
                    state_w = S_WAIT_CALCULATE;
                    StartRead(STATUS_BASE);

                end
            end
        end
        endcase
    end
    S_WAIT_CALCULATE:begin
        //do calculate
        rsa_start_w = 1'd1;
        if(rsa_finished)begin
            rsa_start_w = 1'd0;
            state_w = S_SEND_WAIT;
            dec_w = rsa_dec;
            $display("%h", d_r);
            $display("%h", n_r);
            $display("%h", enc_r);
            $display("cal finish");
            $display("%h", rsa_dec);
        end
    end
    S_SEND_WAIT:begin
        //detect whether tx is ready(avm_waitrequest == 0 && amv_readdata[6] = 1)
        if (!avm_waitrequest) begin
            if(avm_address_r == STATUS_BASE & avm_readdata[TX_OK_BIT] == 1'b1) begin
                // $display("dec");
                StartWrite(TX_BASE);
                state_w = S_SEND_DATA;
            end
            else begin
                StartRead(STATUS_BASE);
                state_w = S_SEND_WAIT;
            end
        end
        else begin
            StartRead(STATUS_BASE);
            state_w = S_SEND_WAIT;

        end
        
    end
    S_SEND_DATA:begin
        //data move to right place
        if (!avm_waitrequest) begin
            if(avm_address_r == TX_BASE & bytes_counter_r<7'd30)begin
                $display("%h", dec_r[247-:8]);
                dec_w = dec_r << 8;
                bytes_counter_w = bytes_counter_r +7'd1;
                state_w = S_SEND_WAIT;
                StartRead(STATUS_BASE);
            end
            else if (avm_address_r == TX_BASE & bytes_counter_r == 7'd30) begin
                $display("%h", dec_r[247-:8]);
                dec_w = dec_r << 8;
                bytes_counter_w = 7'd0;
                state_w = S_GET_KEY;
                StartRead(STATUS_BASE);
            end
        end
    end


    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_GET_KEY;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;

        // data_recieved_r <= 4'd0;
        state_count_r <= GET_N;
        // data_trans_r <= 4'd0;

    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
        // $display(state_r);
        // data_recieved_r <= data_recieved_w;
        state_count_r <= state_count_w;
        // data_trans_r <=data_trans_w;
    end
end

endmodule
