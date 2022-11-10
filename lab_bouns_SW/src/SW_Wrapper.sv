
`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

module SW_Wrapper (
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
localparam S_GET_WAIT = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_WAIT = 3;
localparam S_SEND_DATA = 4;

logic [2*`REF_MAX_LENGTH-1:0] sequence_ref_r, sequence_ref_w; 
logic [2*`READ_MAX_LENGTH-1:0]sequence_read_r, sequence_read_w;
logic [$clog2(`REF_MAX_LENGTH):0] seq_ref_length_r, seq_ref_length_w;
logic [$clog2(`READ_MAX_LENGTH):0] seq_read_length_r, seq_read_length_w;
logic [2:0] state_r, state_w;
logic [4:0] avm_address_r, avm_address_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic sw_start_r, sw_start_w;
logic sw_finished;
logic [`DP_SW_SCORE_BITWIDTH-1:0] alignment_score_w, alignment_score_r, alignment_score;
logic [$clog2(`REF_MAX_LENGTH)-1:0] column_w, column_r, column;
logic [$clog2(`READ_MAX_LENGTH)-1:0] row_w, row_r, row;

logic [2:0] state_get_w, state_get_r;
logic [2:0] state_send_w, state_send_r;

localparam GET_SEQUENCE_REF = 3'd0;
localparam GET_SEQUENCE_READ = 3'd1;
localparam GET_SEQ_REF_LENGTH = 3'd2;
localparam GET_SEQ_READ_LENGTH = 3'd3;

localparam SEND_ALIGNMENT_SCORE = 3'd0;
localparam SEND_COLUMN = 3'd1;
localparam SEND_ROW = 3'd2;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];
// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(),
    .i_valid			(),
    .i_sequence_ref		(sequence_ref_r),
    .i_sequence_read	(sequence_read_r),
    .i_seq_ref_length	(seq_ref_length_r),
    .i_seq_read_length	(seq_read_length_r),
    
    .i_ready			(),
    .o_valid			(),
    .o_alignment_score	(alignment_score),
    .o_column			(column),
    .o_row				(row)
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

// TODO
always_comb begin
    //default value
    state_get_w = state_get_r;
    state_w = state_r;
    avm_address_w = avm_address_r;
    sequence_ref_w = sequence_ref_r;
    sequence_read_w = sequence_read_r;
    seq_ref_length_w = seq_ref_length_r;
    seq_read_length_w = seq_read_length_r;
    bytes_counter_w = bytes_counter_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    sw_start_w = sw_start_r;

    //FSM
    case(state_r)
    S_GET_WAIT:begin
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
        case(state_get_r)
        GET_SEQUENCE_REF:begin
            if (!avm_waitrequest) begin
                if(avm_address_r == RX_BASE & bytes_counter_r<7'd32)begin
                    sequence_ref_w = sequence_ref_w << 8;
                    sequence_ref_w[7:0] = avm_readdata[7:0];
                    state_get_w = state_get_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_WAIT;
                    StartRead(STATUS_BASE);

                end
                else if(avm_address_r == RX_BASE & bytes_counter_r == 7'd32) begin
                    sequence_ref_w = sequence_ref_w << 8;
                    sequence_ref_w[7:0] = avm_readdata[7:0];
                    state_get_w = GET_SEQUENCE_READ;
                    bytes_counter_w = 7'd0;
                    state_w = S_GET_WAIT;
                    StartRead(STATUS_BASE);

                end
            end
        end
        GET_SEQUENCE_READ:begin
            if (!avm_waitrequest) begin
                if(bytes_counter_r < 7'd32)begin
                    sequence_read_w = sequence_read_w << 8;
                    sequence_read_w[7:0] = avm_readdata[7:0];
                    state_get_w = state_get_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_WAIT;
                    StartRead(STATUS_BASE);

                end
                else if (avm_address_r == RX_BASE & bytes_counter_r == 7'd32)begin
                    sequence_read_w = sequence_read_w << 8;
                    sequence_read_w[7:0] = avm_readdata[7:0];
                    state_get_w = GET_SEQUENCE_REF;
                    bytes_counter_w = 7'd0;
                    state_w = S_WAIT_CALCULATE;
                    StartRead(STATUS_BASE);

                end
            end
        end
        // GET_SEQ_REF_LENGTH:begin
        //     if (!avm_waitrequest) begin
        //         if(bytes_counter_r<$clog2(`REF_MAX_LENGTH))begin
        //             seq_ref_length_w = seq_ref_length_w << 8;
        //             seq_ref_length_w[7:0] = avm_readdata[7:0];
        //             state_get_w = state_get_r;
        //             bytes_counter_w = bytes_counter_r +7'd1;
        //             state_w = S_GET_KEY;
        //             StartRead(STATUS_BASE);

        //         end
        //         else if (avm_address_r == RX_BASE & bytes_counter_r == $clog2(`REF_MAX_LENGTH)) begin
        //             seq_ref_length_w = seq_ref_length_w << 8;
        //             seq_ref_length_w[7:0] = avm_readdata[7:0];
        //             state_get_w = GET_SEQ_READ_LENGTH;
        //             bytes_counter_w = 7'd0;
        //             state_w = S_GET_WAIT;
        //             StartRead(STATUS_BASE);

        //         end
        //     end
        // end
        // GET_SEQ_READ_LENGTH:begin
        //     if (!avm_waitrequest) begin
        //         if(bytes_counter_r<$clog2(`READ_MAX_LENGTH))begin
        //             seq_read_length_w = seq_read_length_w << 8;
        //             seq_read_length_w[7:0] = avm_readdata[7:0];
        //             state_get_w = state_get_r;
        //             bytes_counter_w = bytes_counter_r +7'd1;
        //             state_w = S_GET_KEY;
        //             StartRead(STATUS_BASE);

        //         end
        //         else if (avm_address_r == RX_BASE & bytes_counter_r == $clog2(`READ_MAX_LENGTH)) begin
        //             seq_read_length_w = seq_read_length_w << 8;
        //             seq_read_length_w[7:0] = avm_readdata[7:0];
        //             state_get_w = GET_SEQ_READ_LENGTH; //data flow??
        //             bytes_counter_w = 7'd0;
        //             state_w = S_WAIT_CALCULATE;
        //             StartRead(STATUS_BASE);

        //         end
        //     end
        // end
        endcase
    end
    S_WAIT_CALCULATE:begin
        //do calculate
        sw_start_w = 1'd1;
        if(sw_finished)begin
            sw_start_w = 1'd0;
            state_w = S_SEND_WAIT;
            alignment_score_w = alignment_score;
            column_w = column;
            row_w = row;
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
        case(state_send_r) 
        SEND_ALIGNMENT_SCORE: begin
            if (!avm_waitrequest) begin
                if(avm_address_r == TX_BASE & bytes_counter_r<`DP_SW_SCORE_BITWIDTH-1)begin
                    alignment_score_w = alignment_score_r << 8;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_SEND_WAIT;
                    state_send_w = state_send_r;
                    StartRead(STATUS_BASE);
                end
                else if (avm_address_r == TX_BASE & bytes_counter_r == `DP_SW_SCORE_BITWIDTH-1) begin
                    alignment_score_w = alignment_score_r << 8;
                    bytes_counter_w = 7'd0;
                    state_w = S_SEND_WAIT;
                    state_send_w = SEND_COLUMN;
                    StartRead(STATUS_BASE);
                end
            end
        end
        SEND_COLUMN: begin
            if (!avm_waitrequest) begin
                if(avm_address_r == TX_BASE & bytes_counter_r<$clog2(`REF_MAX_LENGTH)-1)begin
                    column_w = column_r << 8;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_SEND_WAIT;
                    state_send_w = state_send_r;
                    StartRead(STATUS_BASE);
                end
                else if (avm_address_r == TX_BASE & bytes_counter_r == $clog2(`REF_MAX_LENGTH)-1) begin
                    column_w = column_r << 8;
                    bytes_counter_w = 7'd0;
                    state_w = S_SEND_WAIT;
                    state_send_w = SEND_ROW;
                    StartRead(STATUS_BASE);
                end
            end
        end
        SEND_ROW: begin
            if (!avm_waitrequest) begin
                if(avm_address_r == TX_BASE & bytes_counter_r<$clog2(`READ_MAX_LENGTH)-1)begin
                    row_w = row_r << 8;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_SEND_WAIT;
                    state_send_w = state_send_r;
                    StartRead(STATUS_BASE);
                end
                else if (avm_address_r == TX_BASE & bytes_counter_r == $clog2(`READ_MAX_LENGTH)-1) begin
                    row_w = row_r << 8;
                    bytes_counter_w = 7'd0;
                    state_w = S_SEND_WAIT; //data flow>
                    state_send_w = SEND_ROW; //data flow?
                    StartRead(STATUS_BASE);
                end
            end
        end
        endcase
    end


    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        sequence_ref_r <= 0;
        sequence_read_r <= 0;
        seq_ref_length_r <= 0;
        seq_read_length_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        bytes_counter_r <= 0;
        sw_start_r <= 0;

        alignment_score_r <= 0;
        column_r <= 0;
        row_r <= 0;

        state_r <= S_GET_WAIT;
        state_get_r <= GET_SEQUENCE_REF;
        state_send_r <= SEND_ALIGNMENT_SCORE;

    end else begin
        sequence_ref_r <= sequence_ref_w;
        sequence_read_r <= sequence_read_w;
        seq_ref_length_r <= seq_ref_length_w;
        seq_read_length_r <= seq_read_length_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        bytes_counter_r <= bytes_counter_w;
        sw_start_r <= sw_start_w;

        alignment_score_r <= alignment_score_w;
        column_r <= column_w;
        row_r <= row_w;

        state_r <= state_w;
        state_get_r <= state_get_w;
        state_send_r <= state_send_w;
    end
end

endmodule
