
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
// SW Core --------------------------------------------
module SW_core(
    input                                       clk,
    input                                       rst,

    output reg                                  o_ready,
    input                                       i_valid,
    input [2*`REF_MAX_LENGTH-1:0]               i_sequence_ref,     // reference seq
    input [2*`READ_MAX_LENGTH-1:0]              i_sequence_read,    // read seq
    input [$clog2(`REF_MAX_LENGTH):0]           i_seq_ref_length,   // (1-based)
    input [$clog2(`READ_MAX_LENGTH):0]          i_seq_read_length,  // (1-based)

    input                                       i_ready,
    output reg                                  o_valid,
    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_alignment_score,
    output reg [$clog2(`REF_MAX_LENGTH)-1:0]    o_column,
    output reg [$clog2(`READ_MAX_LENGTH)-1:0]   o_row
  );
  integer i, j, k, l;

  localparam  S_idle                  = 4'd0,
              S_input                 = 4'd1,
              S_calculate             = 4'd2,
              S_select_highest        = 4'd3,
              S_done                  = 4'd4;

  localparam MOST_NEGATIVE = {1'b1, {(`DP_SW_SCORE_BITWIDTH-1){1'b0}}};

  ///////////////////////////// main registers ////////////////////////////////
  reg [3:0]                                           state, state_n;
  reg [$clog2(`REF_MAX_LENGTH+`READ_MAX_LENGTH):0]    counter, counter_n;
  reg [2*`REF_MAX_LENGTH-1:0]                         sequence_A, sequence_A_n;
  reg [2*`READ_MAX_LENGTH-1:0]                        sequence_B, sequence_B_n;
  reg [$clog2(`REF_MAX_LENGTH):0]                     seq_A_length, seq_A_length_n;
  reg [$clog2(`READ_MAX_LENGTH):0]                    seq_B_length, seq_B_length_n;

  reg                                                 sequence_B_valid[0:`READ_MAX_LENGTH-1], sequence_B_valid_n[0:`READ_MAX_LENGTH-1];
  reg [2*`REF_MAX_LENGTH-1:0]                         sequence_A_shifter, sequence_A_shifter_n;

  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              highest_score, highest_score_n;
  reg [$clog2(`REF_MAX_LENGTH)-1:0]                   column, column_n;
  reg [$clog2(`READ_MAX_LENGTH)-1:0]                  row, row_n;

  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              row_highest_scores[0:`READ_MAX_LENGTH-1], row_highest_scores_n[0:`READ_MAX_LENGTH-1];
  reg [$clog2(`REF_MAX_LENGTH)-1:0]                   row_highest_columns[0:`READ_MAX_LENGTH-1], row_highest_columns_n [0:`READ_MAX_LENGTH-1];

  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_score_buff  [0:`READ_MAX_LENGTH-1], PE_score_buff_n [0:`READ_MAX_LENGTH-1];

  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_align_score_d  [0:`READ_MAX_LENGTH-1], PE_align_score_d_n [0:`READ_MAX_LENGTH-1];
  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_insert_score_d [0:`READ_MAX_LENGTH-1], PE_insert_score_d_n [0:`READ_MAX_LENGTH-1];
  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_delete_score_d [0:`READ_MAX_LENGTH-1], PE_delete_score_d_n [0:`READ_MAX_LENGTH-1];
  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_align_score_dd [0:`READ_MAX_LENGTH-1], PE_align_score_dd_n [0:`READ_MAX_LENGTH-1];
  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_insert_score_dd[0:`READ_MAX_LENGTH-1], PE_insert_score_dd_n [0:`READ_MAX_LENGTH-1];
  reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_delete_score_dd[0:`READ_MAX_LENGTH-1], PE_delete_score_dd_n [0:`READ_MAX_LENGTH-1];

  // output reg
  reg                                 o_valid_n;
  reg [$clog2(`REF_MAX_LENGTH)-1:0]   o_column_n;
  reg [$clog2(`READ_MAX_LENGTH)-1:0]  o_row_n;

  assign o_alignment_score = highest_score;

  //----------------------------------------------------------------------------------------
  wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_align_score          [`READ_MAX_LENGTH:0];
  wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_insert_score         [`READ_MAX_LENGTH:0];
  wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_delete_score         [`READ_MAX_LENGTH:0];

  wire                                    PE_last_A_base_valid    [`READ_MAX_LENGTH:0];
  wire [1:0]                              PE_last_A_base          [`READ_MAX_LENGTH:0];

  genvar gv;
  generate
    for (gv=0;gv<`READ_MAX_LENGTH;gv=gv+1)
    begin: PEs
      if (gv==0)
      begin
        DP_PE_single u_PE_single(
                       ///////////////////////////////////// basics /////////////////////////////////////
                       .clk                        (clk),
                       .rst                        (rst),
                       ///////////////////////////////////// I/Os //////////////////////////////////////
                       .i_A_base_valid             ((state == S_calculate) && (counter < seq_A_length)),
                       .i_A_base                   (sequence_A_shifter[2*`REF_MAX_LENGTH-1-:2] ),

                       .i_B_base_valid             (sequence_B_valid[gv]                       ),
                       .i_B_base                   (sequence_B[2*`READ_MAX_LENGTH-1-(2*gv)-:2] ),

                       .i_align_top_score          ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                       .i_insert_top_score         ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                       .i_align_diagonal_score     ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                       .i_insert_diagonal_score    ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                       .i_delete_diagonal_score    ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),

                       .i_align_left_score         (PE_align_score_d[gv]                       ),
                       .i_insert_left_score        (PE_insert_score_d[gv]                      ),
                       .i_delete_left_score        (PE_delete_score_d[gv]                      ),

                       .o_align_score              (PE_align_score[gv]                         ),
                       .o_insert_score             (PE_insert_score[gv]                        ),
                       .o_delete_score             (PE_delete_score[gv]                        ),

                       .o_the_score                (PE_score_buff_n [gv]                       ),
                       .o_last_A_base_valid        (PE_last_A_base_valid[gv]                   ),
                       .o_last_A_base              (PE_last_A_base[gv]                         )
                     );
      end
      else
      begin
        DP_PE_single u_PE_single(
                       ///////////////////////////////////// basics /////////////////////////////////////
                       .clk                        (clk),
                       .rst                        (rst),
                       ///////////////////////////////////// I/Os //////////////////////////////////////
                       .i_A_base_valid             (PE_last_A_base_valid[gv-1]                 ),
                       .i_A_base                   (PE_last_A_base[gv-1]                       ),
                       .i_B_base_valid             (sequence_B_valid[gv]                       ),
                       .i_B_base                   (sequence_B[2*`READ_MAX_LENGTH-1-(2*gv)-:2] ),

                       .i_align_diagonal_score     (PE_align_score_dd [gv-1]                   ),
                       .i_align_top_score          (PE_align_score_d  [gv-1]                   ),
                       .i_align_left_score         (PE_align_score_d  [gv]                     ),

                       .i_insert_diagonal_score    (PE_insert_score_dd[gv-1]                   ),
                       .i_insert_top_score         (PE_insert_score_d [gv-1]                   ),
                       .i_insert_left_score        (PE_insert_score_d [gv]                     ),

                       .i_delete_diagonal_score    (PE_delete_score_dd[gv-1]                   ),
                       .i_delete_left_score        (PE_delete_score_d [gv]                     ),

                       .o_align_score              (PE_align_score[gv]                         ),
                       .o_insert_score             (PE_insert_score[gv]                        ),
                       .o_delete_score             (PE_delete_score[gv]                        ),

                       .o_the_score                (PE_score_buff_n[gv]                        ),
                       .o_last_A_base_valid        (PE_last_A_base_valid[gv]                   ),
                       .o_last_A_base              (PE_last_A_base[gv]                         )
                     );
      end
    end
  endgenerate

  //////////////////////////// state control ////////////////////////////
  always@(*)
  begin
    state_n = state;
    case(state)
      S_idle:
        state_n = (i_valid) ? S_input : state;
      S_input:
        state_n = S_calculate;
      S_calculate:
        state_n = (counter == seq_A_length + seq_B_length - 1) ? S_select_highest : state;
      S_select_highest:
        state_n = (counter == seq_B_length - 1) ? S_done : state;
      S_done:
        state_n = (i_ready) ? S_idle : state;
    endcase
  end

  ///////////////////// main design ///////////////////
  always@(*)
  begin
    sequence_A_n                                                            = sequence_A;
    sequence_B_n                                                            = sequence_B;
    seq_A_length_n                                                          = seq_A_length;
    seq_B_length_n                                                          = seq_B_length;

    counter_n                                                               = counter;
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      sequence_B_valid_n[i]                = sequence_B_valid[i];
    sequence_A_shifter_n                                                    = sequence_A_shifter;

    highest_score_n                                                         = highest_score;
    column_n                                                                = column;
    row_n                                                                   = row;
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      row_highest_scores_n[i]              = row_highest_scores [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      row_highest_columns_n[i]             = row_highest_columns[i];

    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_align_score_d_n  [i]              = PE_align_score_d [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_insert_score_d_n [i]              = PE_insert_score_d [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_delete_score_d_n [i]              = PE_delete_score_d [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_align_score_dd_n [i]              = PE_align_score_dd [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_insert_score_dd_n[i]              = PE_insert_score_dd [i];
    for (i=0;i<`READ_MAX_LENGTH;i=i+1)
      PE_delete_score_dd_n[i]              = PE_delete_score_dd [i];

    //////////////////////////////////////////// output ports ////////////////////////////////////////////
    o_ready                 = 0;
    o_valid_n               = 0;
    o_column_n              = 0;
    o_row_n                 = 0;

    // *** TODO
    case(state)
      S_idle:
      begin
        if(!i_valid)
        begin
          //reset to 0
          sequence_A_n = 0;
          sequence_B_n = 0;
          seq_A_length_n = 0;
          seq_B_length_n = 0;
          counter_n                                                               = 0;
          sequence_A_shifter_n                                                    = 0;

          highest_score_n                                                         = 0;
          column_n                                                                = 0;
          row_n                                                                   = 0;


          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            sequence_B_valid_n[i]                = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            row_highest_scores_n[i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            row_highest_columns_n[i]             = 0;

          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_align_score_d_n  [i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_insert_score_d_n [i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_delete_score_d_n [i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_align_score_dd_n [i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_insert_score_dd_n[i]              = 0;
          for (i=0;i<`READ_MAX_LENGTH;i=i+1)
            PE_delete_score_dd_n[i]              = 0;

          o_ready = 1;

        end
        else
        begin
          // valid, read input
          sequence_A_n = i_sequence_ref;
          sequence_B_n = i_sequence_read;
          seq_A_length_n = i_seq_ref_length;
          seq_B_length_n = i_seq_read_length;

        end
      end

      S_input:
      begin
        sequence_A_shifter_n = sequence_A;
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          sequence_B_valid_n[i] = 1;

      end

      S_calculate:
      begin
        //counter
        if(counter < `READ_MAX_LENGTH + `REF_MAX_LENGTH - 1)
          counter_n = counter + 1;
        else
          counter_n = 0;

        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        begin
          if(PE_score_buff[i] > row_highest_scores [i]) //why can't be (PE_score_buff[i] >= row_highest_scores [i]) ???
          begin
            row_highest_scores_n[i]              = PE_score_buff[i];
            row_highest_columns_n[i]             = counter - i - 1; //might be wrong
          end
        end
        // now-->left, top-->diagonal
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_align_score_d_n  [i]              = PE_align_score [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_insert_score_d_n [i]              = PE_insert_score [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_delete_score_d_n [i]              = PE_delete_score [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_align_score_dd_n [i]              = PE_align_score_d [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_insert_score_dd_n[i]              = PE_insert_score_d [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1)
          PE_delete_score_dd_n[i]              = PE_delete_score_d [i];
        // shift ref sequence
        sequence_A_shifter_n = sequence_A_shifter << 2;
      end

      S_select_highest:
      begin
        //counter counts the row
        if(counter < `REF_MAX_LENGTH - 1)
          counter_n = counter + 1;
        else
          counter_n = 0;

        // look through the row, find the highest
        if(row_highest_scores [counter] > highest_score) // why can't be (row_highest_scores [counter] >= highest_score) ???
        begin
          highest_score_n = row_highest_scores [counter];
          column_n = row_highest_columns[counter] ;
          row_n = counter;
        end

      end

      S_done:
      begin
        o_valid_n = 1;
        o_column_n              = column;
        o_row_n                 = row;
      end
    endcase
  end

  /////////////////////////////// main ////////////////////////////
  always@(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      state                                                       <= S_idle;
      counter                                                     <= 0;
      sequence_A                                                  <= 0;
      sequence_B                                                  <= 0;
      seq_A_length                                                <= 0;
      seq_B_length                                                <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        sequence_B_valid[i]      <= 0;
      sequence_A_shifter                                          <= 0;

      highest_score                                               <= MOST_NEGATIVE;
      column                                                      <= 0;
      row                                                         <= 0;

      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        row_highest_scores[i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        row_highest_columns[i]   <= 0;

      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_score_buff[i]         <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_align_score_d  [i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_insert_score_d [i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_delete_score_d [i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_align_score_dd [i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_insert_score_dd[i]    <= 0;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_delete_score_dd[i]    <= 0;

      o_valid                     <= 0;
      o_column                    <= 0;
      o_row                       <= 0;
    end
    else
    begin
      state                                                       <= state_n;
      counter                                                     <= counter_n;
      sequence_A                                                  <= sequence_A_n;
      sequence_B                                                  <= sequence_B_n;
      seq_A_length                                                <= seq_A_length_n;
      seq_B_length                                                <= seq_B_length_n;
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        sequence_B_valid[i]      <= sequence_B_valid_n[i];
      sequence_A_shifter                                          <= sequence_A_shifter_n;

      highest_score                                               <= highest_score_n;
      column                                                      <= column_n;
      row                                                         <= row_n;

      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        row_highest_scores[i]    <= row_highest_scores_n [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        row_highest_columns[i]   <= row_highest_columns_n[i];

      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_score_buff[i]         <= PE_score_buff_n[i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_align_score_d  [i]    <= PE_align_score_d_n   [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_insert_score_d [i]    <= PE_insert_score_d_n  [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_delete_score_d [i]    <= PE_delete_score_d_n  [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_align_score_dd [i]    <= PE_align_score_dd_n  [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_insert_score_dd[i]    <= PE_insert_score_dd_n [i];
      for (i=0;i<`READ_MAX_LENGTH;i=i+1)
        PE_delete_score_dd[i]    <= PE_delete_score_dd_n [i];

      o_valid                     <= o_valid_n;
      o_column                    <= o_column_n;
      o_row                       <= o_row_n;
    end
  end

endmodule

module DP_PE_single(
    ///////////////////////////////////// basics /////////////////////////////////////
    input                                       clk,
    input                                       rst,

    ///////////////////////////////////// I/Os //////////////////////////////////////
    input                                       i_A_base_valid,
    input                                       i_B_base_valid,
    input [1:0]                                 i_A_base,          // reference one.   Mapping: reference sequence
    input [1:0]                                 i_B_base,          // query one.       Mapping: short-read

    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_diagonal_score, // H(i-1,j-1)
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_top_score, // H(i-1,j)
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_left_score, //H(i,j-1)

    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_diagonal_score, // I(i-1, j-1)
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_top_score,     // I(i-1,j)
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_left_score,    // if !(i_A_base_valid && i_B_base_valid), o_insert_score = i_insert_left_score

    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_delete_diagonal_score, // D(i-1, j-1)
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_delete_left_score, // D(i,j-1)

    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_align_score, // o_h_ij
    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_insert_score, // o_i_ij
    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_delete_score, // o_d_ij

    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_the_score,            // The highest score among o_align_score, o_insert_score and o_delete_score
    output reg                                  o_last_A_base_valid,
    output reg [1:0]                            o_last_A_base
  );

  // *** TODO
  logic signed [`DP_SW_SCORE_BITWIDTH-1:0] i1, i2, d1, d2, s1, h1, h2, h3;
  logic signed [`DP_SW_SCORE_BITWIDTH-1:0] i_ij, d_ij;

  logic signed [`DP_SW_SCORE_BITWIDTH-1:0] align_score_r, align_score_w, insert_score_r, insert_score_w, delete_score_r, delete_score_w;
  assign o_align_score = align_score_w;
  assign o_insert_score = insert_score_w;
  assign o_delete_score = delete_score_w;
  assign o_the_score = (align_score_w > insert_score_w && align_score_w > delete_score_w && align_score_w > 0) ? align_score_w : (insert_score_w > delete_score_w && insert_score_w > 0) ? insert_score_w : (delete_score_w > 0) ? delete_score_w : 0;

  always_comb
  begin
    //default
    // align_score_w = align_score_r;
    // insert_score_w = insert_score_r;
    // delete_score_w = delete_score_r;

    if (!(i_A_base_valid && i_B_base_valid))
    begin
      insert_score_w = i_insert_left_score;
      delete_score_w = i_delete_left_score;
      align_score_w = i_align_left_score;

    end
    else
    begin
      //insert I
      i1 = i_align_top_score + $signed(`CONST_GAP_OPEN); //I(i,j)=H(i-1,j)+gap_o
      i2 = i_insert_top_score + $signed(`CONST_GAP_EXTEND);//I(i,j)=I(i-1,j)+gap_e
      if(i1 > i2 && i1 > 0)
      begin
        insert_score_w = i1;
        i_ij = i1;
      end
      else if(i2 > 0)
      begin
        insert_score_w = i2;
        i_ij = i2;
      end
      else
      begin
        insert_score_w = 0;
        i_ij = 0;
      end
      //delete D
      d1 = i_align_left_score + $signed(`CONST_GAP_OPEN); //D(i,j)=H(i,j-1)+gap_o
      d2 = i_delete_left_score + $signed(`CONST_GAP_EXTEND); //D(i,j)=D(i,j-1)+gap_e
      if(d1 > d2 && d1 > 0)
      begin
        delete_score_w = d1;
        d_ij = d1;
      end
      else if(d2 > 0)
      begin
        delete_score_w = d2;
        d_ij = d2;
      end
      else
      begin
        delete_score_w = 0;
        d_ij = 0;
      end
      //align H
      s1 = (i_A_base == i_B_base) ? $signed(`CONST_MATCH_SCORE) : $signed(`CONST_MISMATCH_SCORE);
      h1 = i_align_diagonal_score + s1;
      h2 = i_ij;
      h3 = d_ij;
      if (h1 > h2 && h1 > h3 && h1 > 0)
      begin
        align_score_w = h1;
      end
      else if (h2 > h3 && h2 > 0)
      begin
        align_score_w = h2;
      end
      else if (h3 > 0)
      begin
        align_score_w = h3;
      end
      else
      begin
        align_score_w = 0;
      end

    end
  end

  always@(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      o_last_A_base_valid <= 0;
      o_last_A_base       <= 0;
    end
    else
    begin
      o_last_A_base_valid <= i_A_base_valid;
      o_last_A_base       <= i_A_base;
    end
  end

endmodule
