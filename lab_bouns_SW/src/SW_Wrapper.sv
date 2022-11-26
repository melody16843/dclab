
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
logic   [255:0]     write_data_r, write_data_w;

logic [2:0] state_get_w, state_get_r;
logic [2:0] state_send_w, state_send_r;
logic output_ready, output_valid;

localparam GET_SEQUENCE_REF = 3'd0;
localparam GET_SEQUENCE_READ = 3'd1;
localparam GET_SEQ_REF_LENGTH = 3'd2;
localparam GET_SEQ_READ_LENGTH = 3'd3;

localparam SEND_NULL = 3'd0;
localparam SEND_COLUMN = 3'd1;
localparam SEND_ROW = 3'd2;
localparam SEND_ALIGNMENT_SCORE = 3'd3;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = write_data_r[247-:8];

// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(output_ready),
    .i_valid			(sw_start_w),
    .i_sequence_ref		(sequence_ref_r),
    .i_sequence_read	(sequence_read_r),
    .i_seq_ref_length	(`REF_MAX_LENGTH),
    .i_seq_read_length	(`READ_MAX_LENGTH),
    
    .i_ready			(sw_start_w),
    .o_valid			(output_valid),
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
    bytes_counter_w = bytes_counter_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    sw_start_w = sw_start_r;
    write_data_w = write_data_r;

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
                state_w = S_GET_WAIT;
            end
        end
        else begin
            StartRead(STATUS_BASE);
            state_w = S_GET_WAIT;

        end
    end
    S_GET_DATA:begin
        //read data to rignt place
        // n d enc each has 256bit. since readdata only provide 8 bit, we need to load 32 times.
        // decide go to next or not
        case(state_get_r)
        GET_SEQUENCE_REF:begin
            if (!avm_waitrequest) begin
                if(avm_address_r == RX_BASE & bytes_counter_r<7'd31)begin
                    sequence_ref_w = sequence_ref_w << 8;
                    sequence_ref_w[7:0] = avm_readdata[7:0];
                    state_get_w = state_get_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_WAIT;
                    StartRead(STATUS_BASE);

                end
                else if(avm_address_r == RX_BASE & bytes_counter_r == 7'd31) begin
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
                if(bytes_counter_r < 7'd31)begin
                    sequence_read_w = sequence_read_w << 8;
                    sequence_read_w[7:0] = avm_readdata[7:0];
                    state_get_w = state_get_r;
                    bytes_counter_w = bytes_counter_r +7'd1;
                    state_w = S_GET_WAIT;
                    StartRead(STATUS_BASE);
                end
                else if (avm_address_r == RX_BASE & bytes_counter_r == 7'd31)begin
                    sequence_read_w = sequence_read_w << 8;
                    sequence_read_w[7:0] = avm_readdata[7:0];
                    state_get_w = GET_SEQUENCE_REF;
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
        sw_start_w = 1'd1;
        if(output_valid)begin
            sw_start_w = 1'd0;
            state_w = S_SEND_WAIT;
            write_data_w = {64'd0, 57'd0, column, 57'd0, row, 54'd0, alignment_score};
        end
    end

    S_SEND_WAIT:begin
        //detect whether tx is ready(avm_waitrequest == 0 && amv_readdata[6] = 1)
        if (!avm_waitrequest) begin
            if(avm_address_r == STATUS_BASE & avm_readdata[TX_OK_BIT] == 1'b1) begin
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

    S_SEND_DATA:
    begin
        if (!avm_waitrequest)
        begin
            if (avm_address_r == TX_BASE & bytes_counter_r < 7'd30)
            begin
                write_data_w = write_data_r << 8;
                bytes_counter_w = bytes_counter_r + 1;
                state_w = S_SEND_WAIT;
                StartRead(STATUS_BASE);
            end
            else if (avm_address_r == TX_BASE & bytes_counter_r == 7'd30)
            begin
                write_data_w = write_data_r << 8;
                bytes_counter_w = 7'd0;
                state_w = S_GET_WAIT;
                StartRead(STATUS_BASE);
            end

        end
    end
    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        sequence_ref_r <= 0;
        sequence_read_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        bytes_counter_r <= 0;
        sw_start_r <= 0;
        write_data_r <= 0;
        state_r <= S_GET_WAIT;
        state_get_r <= GET_SEQUENCE_REF;
    end 
    else begin
        sequence_ref_r <= sequence_ref_w;
        sequence_read_r <= sequence_read_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        bytes_counter_r <= bytes_counter_w;
        sw_start_r <= sw_start_w;
        write_data_r <= write_data_w;
        state_r <= state_w;
        state_get_r <= state_get_w; 
    end
end

endmodule
