module disparity_calculation(
    input clk,
    input rst_n,
    input i_valid_l,
    input i_valid_r,
    input [8:0] i_data_l,
    input [8:0] i_data_r,
    output o_valid,
    output [9:0]o_data_R,
    output [9:0]o_data_G,
    output [9:0]o_data_B
);

reg [9:0] counter_l_t, counter_l_r;
reg [9:0] counter_r_t, counter_r_r;
reg [7199:0] target_row_l;
reg [7199:0] target_row_r;
reg [7199:0] result;
// reg [71:0] target_row_l;
// reg [71:0] target_row_r;
reg [1:0] state_t, state_r;
reg [3:0] offset_t, offset_r;
reg valid_ctr_l, valid_ctr_r, i_valid_l_r, i_valid_r_r;

parameter S_FETCH = 2'd0;
parameter S_CALCULATE = 2'd1;
parameter S_OUTPUT = 2'd2;

reg [9:0] o_data_R_reg, o_data_G_reg, o_data_B_reg;
assign o_data_R = o_data_R_reg;
assign o_data_G = o_data_G_reg;
assign o_data_B = o_data_B_reg;

// reg [16:0] min_sum_1_t, min_sum_1_r, min_sum_2_t, min_sum_2_r, min_sum_3_t, min_sum_3_r, min_sum_4_t, min_sum_4_r; 

reg [8:0] current_p1_1, current_p2_1, current_p3_1, current_p4_1;
reg [8:0] offset_p1_1, offset_p2_1, offset_p3_1, offset_p4_1;
reg [16:0] temp1_1, temp2_1, temp3_1, temp4_1, min_sum_1_t, min_sum_1_r;
reg [3:0] disparity_1;

reg [8:0] current_p1_2, current_p2_2, current_p3_2, current_p4_2;
reg [8:0] offset_p1_2, offset_p2_2, offset_p3_2, offset_p4_2;
reg [16:0] temp1_2, temp2_2, temp3_2, temp4_2, min_sum_2_t, min_sum_2_r;
reg [3:0] disparity_2;

reg [8:0] current_p1_3, current_p2_3, current_p3_3, current_p4_3;
reg [8:0] offset_p1_3, offset_p2_3, offset_p3_3, offset_p4_3;
reg [16:0] temp1_3, temp2_3, temp3_3, temp4_3, min_sum_3_t, min_sum_3_r;
reg [3:0] disparity_3;

reg [8:0] current_p1_4, current_p2_4, current_p3_4, current_p4_4;
reg [8:0] offset_p1_4, offset_p2_4, offset_p3_4, offset_p4_4;
reg [16:0] temp1_4, temp2_4, temp3_4, temp4_4, min_sum_4_t, min_sum_4_r;
reg [3:0] disparity_4;

wire [9:0] count_multiply_l, offset_multiply_r;
assign count_multiply_l = (counter_l_r<<7)+(counter_l_r<<4);
assign offset_multiply_r = offset_r<<3+offset_r;
wire [9:0] count_multiply9_l;
assign count_multiply9_l = counter_l_r<<3+counter_l_r;


always @(*) begin
    //default
    counter_l_t = counter_l_r;
    counter_r_t = counter_r_r;
    state_t = state_r;
    offset_t = offset_r;
    min_sum_1_t = min_sum_1_r;
    min_sum_2_t = min_sum_2_r;
    min_sum_3_t = min_sum_3_r;
    min_sum_4_t = min_sum_4_r;
    target_row_l = 0;
    target_row_r = 0;
    result = 0;
    o_data_R_reg = 0;
    o_data_G_reg = 0;
    o_data_B_reg = 0;

    current_p1_1 = 0;
    current_p2_1 = 0;
    current_p3_1 = 0;
    current_p4_1 = 0;
    offset_p1_1 = 0;
    offset_p2_1 = 0;
    offset_p3_1 = 0;
    offset_p4_1 = 0;

    current_p1_2 = 0;
    current_p2_2 = 0;
    current_p3_2 = 0;
    current_p4_2 = 0;
    offset_p1_2 = 0;
    offset_p2_2 = 0;
    offset_p3_2 = 0;
    offset_p4_2 = 0;

    current_p1_3 = 0;
    current_p2_3 = 0;
    current_p3_3 = 0;
    current_p4_3 = 0;
    offset_p1_3 = 0;
    offset_p2_3 = 0;
    offset_p3_3 = 0;
    offset_p4_3 = 0;

    current_p1_4 = 0;
    current_p2_4 = 0;
    current_p3_4 = 0;
    current_p4_4 = 0;
    offset_p1_4 = 0;
    offset_p2_4 = 0;
    offset_p3_4 = 0;
    offset_p4_4 = 0;

    temp1_1 = 0;
    temp2_1 = 0;
    temp3_1 = 0;
    temp4_1 = 0;

    temp1_2 = 0;
    temp2_2 = 0;
    temp3_2 = 0;
    temp4_2 = 0;

    temp1_3 = 0;
    temp2_3 = 0;
    temp3_3 = 0;
    temp4_3 = 0;

    temp1_4 = 0;
    temp2_4 = 0;
    temp3_4 = 0;
    temp4_4 = 0;

    disparity_1 = 0;
    disparity_2 = 0;
    disparity_3 = 0;
    disparity_4 = 0;
    case(state_r)
    S_FETCH: begin
        if (i_valid_l^i_valid_l_r && counter_l_r<10'd800 && i_valid_l) begin
            counter_l_t = counter_l_r + 10'd1;
            target_row_l[count_multiply9_l+:9] = i_data_l;
        end
        if (i_valid_r^i_valid_r_r && counter_r_r<10'd800 && i_valid_r) begin
            counter_r_t = counter_r_r + 10'd1;
            target_row_r[9*counter_r_r+:9] = i_data_r;
        end
        if (counter_l_r == 10'd800 && counter_r_r == 10'd800) begin
            counter_r_t = 0;
            counter_l_t = 0;
            state_t = S_CALCULATE;
        end
        // if(i_valid_l) begin
        //     target_row_l = i_data_l;
        //     valid_ctr_l = 1;
        // end
        // if (i_valid_r) begin
        //     target_row_r = i_data_r;
        //     valid_ctr_r = 1;
        // end
        // if (valid_ctr_l & valid_ctr_r) begin
        //     state_t = S_CALCULATE;
        // end
    end
    S_CALCULATE:begin
        //can calculate more than one window in a time
        //1
        current_p1_1 = target_row_r[count_multiply_l+:9];
        current_p2_1 = target_row_r[count_multiply_l+9+:9];
        current_p3_1 = target_row_r[count_multiply_l+18+:9];
        current_p4_1 = target_row_r[count_multiply_l+27+:9];
        if (((counter_l_r<<4)+offset_r)<10'd797)begin
            offset_p1_1 = target_row_l[count_multiply_l+offset_multiply_r+:9];
            offset_p2_1 = target_row_l[count_multiply_l+offset_multiply_r+9+:9];
            offset_p3_1 = target_row_l[count_multiply_l+offset_multiply_r+18+:9];
            offset_p4_1 = target_row_l[count_multiply_l+offset_multiply_r+27+:9];
        end
        else begin
            offset_p1_1 = 0;
            offset_p2_1 = 0;
            offset_p3_1 = 0;
            offset_p4_1 = 0;
        end
        
        temp1_1 = (current_p1_1-offset_p1_1)? (current_p1_1-offset_p1_1):(offset_p1_1-current_p1_1);
        temp2_1 = (current_p2_1-offset_p2_1)? (current_p2_1-offset_p2_1):(offset_p2_1-current_p2_1);
        temp3_1 = (current_p3_1-offset_p3_1)? (current_p3_1-offset_p3_1):(offset_p3_1-current_p3_1);
        temp4_1 = (current_p4_1-offset_p3_1)? (current_p3_1-offset_p3_1):(offset_p4_1-current_p4_1);

        //2
        current_p1_2 = target_row_r[count_multiply_l+36+:9];
        current_p2_2 = target_row_r[count_multiply_l+45+:9];
        current_p3_2 = target_row_r[count_multiply_l+54+:9];
        current_p4_2 = target_row_r[count_multiply_l+63+:9];
        if ((counter_l_r<<4+4)+offset_r<10'd797)begin
            offset_p1_2 = target_row_l[count_multiply_l+offset_multiply_r+36+:9];
            offset_p2_2 = target_row_l[count_multiply_l+offset_multiply_r+45+:9];
            offset_p3_2 = target_row_l[count_multiply_l+offset_multiply_r+54+:9];
            offset_p4_2 = target_row_l[count_multiply_l+offset_multiply_r+63+:9];
        end
        else begin
            offset_p1_2 = 0;
            offset_p2_2 = 0;
            offset_p3_2 = 0;
            offset_p4_2 = 0;
        end
        temp1_2 = (current_p1_2>offset_p1_2)? (current_p1_2-offset_p1_2):(offset_p1_2-current_p1_2);
        temp2_2 = (current_p2_2>offset_p2_2)? (current_p2_2-offset_p2_2):(offset_p2_2-current_p2_2);
        temp3_2 = (current_p3_2>offset_p3_2)? (current_p3_2-offset_p3_2):(offset_p3_2-current_p3_2);
        temp4_2 = (current_p3_2>offset_p3_2)? (current_p3_2-offset_p3_2):(offset_p4_2-current_p4_2);

        //3
        current_p1_3 = target_row_r[count_multiply_l+72+:9];
        current_p2_3 = target_row_r[count_multiply_l+81+:9];
        current_p3_3 = target_row_r[count_multiply_l+90+:9];
        current_p4_3 = target_row_r[count_multiply_l+99+:9];
        if ((counter_l_r<<4+8)+offset_r<10'd797)begin
            offset_p1_3 = target_row_l[count_multiply_l+offset_multiply_r+72+:9];
            offset_p2_3 = target_row_l[count_multiply_l+offset_multiply_r+81+:9];
            offset_p3_3 = target_row_l[count_multiply_l+offset_multiply_r+90+:9];
            offset_p4_3 = target_row_l[count_multiply_l+offset_multiply_r+99+:9];
        end
        else begin
            offset_p1_3 = 0;
            offset_p2_3 = 0;
            offset_p3_3 = 0;
            offset_p4_3 = 0;
        end
        temp1_3 = (current_p1_3-offset_p1_3)?(current_p1_3-offset_p1_3):(offset_p1_3-current_p1_3);
        temp2_3 = (current_p2_3-offset_p2_3)?(current_p2_3-offset_p2_3):(offset_p2_3-current_p2_3);
        temp3_3 =  (current_p3_3-offset_p3_3)?(current_p3_3-offset_p3_3):(offset_p3_3-current_p3_3);
        temp4_3 = (current_p4_3-offset_p4_3)?(current_p4_3-offset_p4_3):(offset_p4_3-current_p4_3);

        //4
        current_p1_4 = target_row_r[count_multiply_l+108+:9];
        current_p2_4 = target_row_r[count_multiply_l+117+:9];
        current_p3_4 = target_row_r[count_multiply_l+126+:9];
        current_p4_4 = target_row_r[count_multiply_l+135+:9];
        if ((counter_l_r<<4+12)+offset_r<10'd798)begin
            offset_p1_4 = target_row_l[count_multiply_l+offset_multiply_r+108+:9];
            offset_p2_4 = target_row_l[count_multiply_l+offset_multiply_r+117+:9];
            offset_p3_4 = target_row_l[count_multiply_l+offset_multiply_r+126+:9];
            offset_p4_4 = target_row_l[count_multiply_l+offset_multiply_r+135+:9];
        end
        else begin
            offset_p1_4 = 0;
            offset_p2_4 = 0;
            offset_p3_4 = 0;
            offset_p4_4 = 0;
        end
        temp1_4 = (current_p1_4-offset_p1_4)? (current_p1_4-offset_p1_4):(offset_p1_4-current_p1_4);
        temp2_4 = (current_p2_4-offset_p2_4)? (current_p2_4-offset_p2_4):(offset_p2_4-current_p2_4);
        temp3_4 = (current_p3_4-offset_p3_4)? (current_p3_4-offset_p3_4):(offset_p3_4-current_p3_4);
        temp4_4 = (current_p4_4-offset_p4_4)? (current_p4_4-offset_p4_4):(offset_p4_4-current_p4_4);

        //calculate minimum distance 
        if (temp1_1+temp2_1+temp3_1+temp4_1<min_sum_1_r && (current_p1_1 || current_p2_1 || current_p3_1 || current_p4_1) && (offset_p1_1 || offset_p2_1 || offset_p3_1 || offset_p4_1))begin
            min_sum_1_t = temp1_1+temp2_1+temp3_1+temp4_1;
            disparity_1 = offset_r;
        end
        if (temp1_2+temp2_2+temp3_2+temp4_2<min_sum_2_r && (current_p1_2 || current_p2_2 || current_p3_2 || current_p4_2) && (offset_p1_2 || offset_p2_2 || offset_p3_2 || offset_p4_2))begin
            min_sum_2_t = temp1_2+temp2_2+temp3_2+temp4_2;
            disparity_2 = offset_r;
        end
        if (temp1_3+temp2_3+temp3_3+temp4_3<min_sum_3_r && (current_p1_3 || current_p2_3 || current_p3_3 || current_p4_3) && (offset_p1_3 || offset_p2_3 || offset_p3_3 || offset_p4_3))begin
            min_sum_3_t = temp1_3+temp2_3+temp3_3+temp4_3;
            disparity_3 = offset_r;
        end
        if (temp1_4+temp2_4+temp3_4+temp4_4<min_sum_4_r && (current_p1_4 || current_p2_4 || current_p3_4 || current_p4_4) && (offset_p1_4 || offset_p2_4 || offset_p3_4 || offset_p4_4))begin
            min_sum_4_t = temp1_4+temp2_4+temp3_4+temp4_4;
            disparity_4 = offset_r;
        end


        if (offset_r< 9)begin
            offset_t = offset_r+1;
        end
        else begin // after calculate 10 times record the disparity of minimum sum at original place
            offset_t = 0;
            result[count_multiply_l+:9] = {5'b0,disparity_1};
            result[count_multiply_l+9+:9] = {5'b0,disparity_1};
            result[count_multiply_l+18+:9] = {5'b0,disparity_1};
            result[count_multiply_l+27+:9] = {5'b0,disparity_1};

            result[count_multiply_l+36+:9] = {5'b0,disparity_2};
            result[count_multiply_l+45+:9] = {5'b0,disparity_2};
            result[count_multiply_l+54+:9] = {5'b0,disparity_2};
            result[count_multiply_l+63+:9] = {5'b0,disparity_2};

            result[count_multiply_l+72+:9] = {5'b0,disparity_3};
            result[count_multiply_l+81+:9] = {5'b0,disparity_3};
            result[count_multiply_l+90+:9] = {5'b0,disparity_3};
            result[count_multiply_l+99+:9] = {5'b0,disparity_3};

            result[count_multiply_l+108+:9] = {5'b0,disparity_4};
            result[count_multiply_l+117+:9] = {5'b0,disparity_4};
            result[count_multiply_l+126+:9] = {5'b0,disparity_4};
            result[count_multiply_l+135+:9] = {5'b0,disparity_4};
            counter_l_t = counter_l_r+1;
            min_sum_1_t = 17'd131071;
            min_sum_2_t = 17'd131071;
            min_sum_3_t = 17'd131071;
            min_sum_4_t = 17'd131071;
        end

        if (counter_l_r==10'd99)begin
            counter_l_t = 0;
            state_t = S_OUTPUT;
        end
    end
    S_OUTPUT:begin 

        if (result[count_multiply9_l+:9] == 0) begin
            o_data_R_reg = 255;
            o_data_G_reg = 0;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 1) begin
            o_data_R_reg = 255;
            o_data_G_reg = 64;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 2) begin
            o_data_R_reg = 255;
            o_data_G_reg = 136;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 3) begin
            o_data_R_reg = 255;
            o_data_G_reg = 221;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 4) begin
            o_data_R_reg = 153;
            o_data_G_reg = 255;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 5) begin
            o_data_R_reg = 26;
            o_data_G_reg = 255;
            o_data_B_reg = 0;
        end
        else if (result[count_multiply9_l+:9] == 6) begin
            o_data_R_reg = 0;
            o_data_G_reg = 255;
            o_data_B_reg = 162;
        end
        else if (result[count_multiply9_l+:9] == 7) begin
            o_data_R_reg = 0;
            o_data_G_reg = 212;
            o_data_B_reg = 255;
        end
        else if (result[count_multiply9_l+:9] == 8) begin
            o_data_R_reg = 0;
            o_data_G_reg = 98;
            o_data_B_reg = 255;
        end
        else if (result[count_multiply9_l+:9] == 9) begin
            o_data_R_reg = 47;
            o_data_G_reg = 0;
            o_data_B_reg = 255;
        end
        if (counter_l_r<10'd800) counter_l_t = counter_l_r + 1;
        else begin
            counter_l_t = 0;
            state_t = S_FETCH;
            valid_ctr_l = 0;
            valid_ctr_r = 0;
        end

    end
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        counter_l_r <=0;
        counter_r_r <=0;
        offset_r <=0;
        min_sum_1_r <= 17'd131071;
        min_sum_2_r <= 17'd131071;
        min_sum_3_r <= 17'd131071;
        min_sum_4_r <= 17'd131071;
        valid_ctr_l <=0;
        valid_ctr_r <=0;
        state_r <=0;
        i_valid_l_r <=0;
        i_valid_r_r <=0;
    end
    else begin
        counter_l_r <=counter_l_t;
        counter_r_r <=counter_r_t;
        offset_r <=offset_t;
        min_sum_1_r <= min_sum_1_t;
        min_sum_2_r <= min_sum_2_t;
        min_sum_3_r <= min_sum_3_t;
        min_sum_4_r <= min_sum_4_t;
        state_r <= state_t;
        i_valid_l_r <= i_valid_l;
        i_valid_r_r <= i_valid_r;
    end

end


endmodule
