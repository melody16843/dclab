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
logic [1:0] state_r, state_w;
logic [4:0] avm_address_r, avm_address_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

logic [2:0] state_count_w, state_count_r;
logic [6:0] data_recived_w, data_recived_r;
logic [9:0] data_trans_w, data_trans_r;

localparam GET_N = 2'd0;
localparam GET_D = 2'd1;
localparam GET_ENC = 2'd2;
localparam READY_CAL = 2'd3;

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
    case(state_r)
    S_GET_KEY:begin
        if(avm_readdata[7] == 1'b1) begin
            avm_read_w = 1;
            avm_write_w = 0;
            avm_address_w = RX_BASE;
            state_w = S_GET_DATA;
        end
        else begin
            avm_read_w = avm_read_r;
            avm_write_w = avm_write_r;
            avm_address_w = avm_address_r;
            state_w = S_GET_KEY;
        end
    end
    S_GET_DATA:begin
        //read data to rignt place
        // decide got to nxt ot not 
        case(state_count_r)
        GET_N:begin
            if(bytes_counter_r<7'd32)begin
                n_w = {(n_r << 8), avm_readdata[7:0]};
                state_count_w = state_count_r;
                bytes_counter_w = bytes_counter_r +7'd1;
                state_w = state_r;
            end
            else begin
                n_w = n_r;
                state_count_w = GET_D;
                bytes_counter_w = 7'd0;
                state_w = state_r;
            end
        end
        GET_D:begin
            if(bytes_counter_r<7'd32)begin
                d_w = {(d_r << 8), avm_readdata[7:0]};
                state_count_w = state_count_r;
                bytes_counter_w = bytes_counter_r +7'd1;
                state_w = state_r;
            end
            else begin
                d_w = d_r;
                state_count_w = GET_ENC;
                bytes_counter_w = 7'd0;
                state_w = state_r;
            end
        end
        GET_ENC:begin
            if(bytes_counter_r<7'd32)begin
                enc_w = {(enc_r << 8), avm_readdata[7:0]};
                state_count_w = state_count_r;
                bytes_counter_w = bytes_counter_r +7'd1;
                state_w = state_r;
            end
            else begin
                enc_w = enc_r;
                state_count_w = READY_CAL;
                bytes_counter_w = 7'd0;
                state_w = state_r;
            end
        end
        READY_CAL:begin
            state_w = GET_N;
            bytes_counter_w = 7'd0;
            state_w = S_WAIT_CALCULATE;
        end
        endcase
    end
    S_WAIT_CALCULATE:begin
        if(!rsa_finished)begin
            rsa_start_w = 1'd1;
            state_w = state_r;
        end
        else begin
            rsa_start_w = 1'd0;
            state_w = S_SEND_WAIT;
        end
    end
    S_SEND_WAIT:begin
        if(avm_readdata[7] == 1'b1) begin
            avm_read_w = 1;
            avm_write_w = 0;
            avm_address_w = TX_BASE;
            state_w = S_SEND_DATA;
        end
        else begin
            avm_read_w = avm_read_r;
            avm_write_w = avm_write_r;
            avm_address_w = avm_address_r;
            state_w = state_r;
        end
    end
    S_SEND_DATA:begin
    if(bytes_counter_r<7'd32)begin
            dec_w = {(dec_r << 8), (rsa_dec<<8)[255:248]};
            bytes_counter_w = bytes_counter_r +7'd1;
            state_w = state_r;
        end
        else begin
            dec_w = dec_r;
            bytes_counter_w = 7'd0;
            state_w = S_GET_KEY;
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
        // state_count_r <= 2'd0;
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

        // data_recieved_r <= data_recieved_w;
        // state_count_r <= state_count_w;
        // data_trans_r <=data_trans_w;
    end
end

endmodule
