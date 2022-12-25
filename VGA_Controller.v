// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	VGA_Controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN Peli Li:| 22/07/2010:| Initial Revision
// --------------------------------------------------------------------

module	VGA_Controller(	//	Host Side
iRed,
iGreen,
iBlue,
oRequest,
//	VGA Side
oVGA_R,
oVGA_G,
oVGA_B,
oVGA_H_SYNC,
oVGA_V_SYNC,
oVGA_SYNC,
oVGA_BLANK,

//	Control Signal
iCLK,
iRST_N,
iZOOM_MODE_SW
  );
`include "VGA_Param.h"

`ifdef VGA_640x480p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;

//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525; 

`else
// SVGA_800x600p60
////	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;         //Peli
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

`endif
//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;
//	Host Side
input		[9:0]	iRed;
input		[9:0]	iGreen;
input		[9:0]	iBlue;
output	reg			oRequest;
//	VGA Side
output	reg	[9:0]	oVGA_R;
output	reg	[9:0]	oVGA_G;
output	reg	[9:0]	oVGA_B;
output	reg			oVGA_H_SYNC;
output	reg			oVGA_V_SYNC;
output	reg			oVGA_SYNC;
output	reg			oVGA_BLANK;

wire		[9:0]	mVGA_R;
wire		[9:0]	mVGA_G;
wire		[9:0]	mVGA_B;
reg					mVGA_H_SYNC;
reg					mVGA_V_SYNC;
wire				mVGA_SYNC;
wire				mVGA_BLANK;

//	Control Signal
input				iCLK;
input				iRST_N;
input 				iZOOM_MODE_SW;

//	Internal Registers and Wires
reg		[12:0]		H_Cont;
reg		[12:0]		V_Cont;

wire	[12:0]		v_mask;


// blur register
parameter BW = 10500;
// reg 	[9:0]		iRed_p1, iRed_p2, iRed_r, iGreen_p1, iGreen_p2, iGreen_r, iBlue_p1, iBlue_p2, iBlue_r;

// reg 	[9:0]		iRed_blur, iRed_blur_w, iGreen_blur, iGreen_blur_w, iBlue_blur, iBlue_blur_w, iGrey_blur, iGrey_blur_w, iGrey;
// reg 	[BW-1:0]	R_row, R_row_w, G_row, G_row_w, B_row, B_row_w;
// reg 	[BW-1:0]	GR_row1, GR_row1_w, GR_row2, GR_row2_w, GR_row3, GR_row3_w;
reg 	[$clog2(BW):0] 	count_x, count_x_w;
reg  	[$clog2(BW):0]	count_y, count_y_w;
reg   [9:0] temp_red[$clog2(BW):0];
reg   [9:0] temp_red_w[$clog2(BW):0];
reg   [9:0] temp_blue[$clog2(BW):0];
reg   [9:0] temp_blue_w[$clog2(BW):0];
reg   [9:0] temp_green[$clog2(BW):0];
reg   [9:0] temp_green_w[$clog2(BW):0];
reg   [9:0] display_red, display_green, display_blue; // the color displayed
reg   [9:0] display_red_w, display_green_w, display_blue_w;

assign v_mask = 13'd0 ;//iZOOM_MODE_SW ? 13'd0 : 13'd26;

////////////////////////////////////////////////////////

wire	[9:0]	U;
wire	[9:0]	V;
wire	[9:0] V_minus;

assign	U = iRed - iGreen;
assign 	V = iBlue - iGreen;
assign  	V_minus = iGreen - iBlue;

assign	mVGA_BLANK	=	mVGA_H_SYNC & mVGA_V_SYNC;
assign	mVGA_SYNC	=	1'b0;

// assign	mVGA_R	=	(U > 10'd200 && U < 10'd450 && iRed > iBlue) ? ((	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 																			V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 																			?	iRed	:	0) : iRed_r;
// assign	mVGA_G	=	(U > 10'd200 && U < 10'd450 && iRed > iBlue) ? ((	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 																			V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 																			?	iGreen	:	0) : iGreen_r;
// assign	mVGA_B	=	(U > 10'd200 && U < 10'd450 && iRed > iBlue) ? ((	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
// 																			V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
// 																			?	iBlue	:	0) : iBlue_r;

assign	mVGA_R	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
?	display_red_w	:	0;
assign	mVGA_G	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
?	display_green_w	:	0;
assign	mVGA_B	=	(	H_Cont>=X_START 	&& H_Cont<X_START+H_SYNC_ACT &&
V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
?	display_blue_w	:	0;




always @(*)
begin
  //default
  temp_red_w = temp_red;
  temp_blue_w = temp_blue;
  temp_green_w = temp_green;

  if (((count_x%16) == 0)&&((count_y%16) == 0)) // put the color into temp
  begin
    temp_red_w[(count_x/16)] = iRed;
    temp_blue_w[(count_x/16)] = iBlue;
    temp_green_w[(count_x/16)] = iGreen;
    display_red_w = iRed;
    display_blue_w = iBlue;
    display_green_w = iGreen;
  end
  else
  begin
    display_red_w = temp_red[(count_x/16)];
    display_green_w = temp_green[(count_x/16)];
    display_blue_w = temp_blue[(count_x/16)];
  end

end

//counter
always @(*)
begin
  //default
  count_x_w = count_x;
  count_y_w = count_y;

  if(count_x == 1050)  //if(count_x == (BW/10))
  begin
    count_x_w = 0;
    count_y_w = count_y + 1;
  end
  else
  begin
    count_x_w = count_x + 1;
  end
end

always@(posedge iCLK or negedge iRST_N)
begin
if (!iRST_N)
begin
count_x <= 0;
count_y <= 0;
temp_red <= 0;
temp_blue <= 0;
temp_green <= 0;
display_red <= 0;
display_blue <= 0;
display_green <= 0;

end
else
begin

count_x <= count_x_w;
count_y <= count_y_w;
temp_red <= temp_red_w;
temp_blue <= temp_blue_w;
temp_green <= temp_green_w;
display_blue <= display_blue_w;
display_green <= display_green_w;
display_red <= display_red_w;

end

end

always@(posedge iCLK or negedge iRST_N)
begin
if (!iRST_N)
begin
oVGA_R <= 0;
oVGA_G <= 0;
    oVGA_B <= 0;
oVGA_BLANK <= 0;
oVGA_SYNC <= 0;
oVGA_H_SYNC <= 0;
oVGA_V_SYNC <= 0; 
end
else
begin
oVGA_R <= mVGA_R;
oVGA_G <= mVGA_G;
    oVGA_B <= mVGA_B;
oVGA_BLANK <= mVGA_BLANK;
oVGA_SYNC <= mVGA_SYNC;
oVGA_H_SYNC <= mVGA_H_SYNC;
oVGA_V_SYNC <= mVGA_V_SYNC;				
end               
end



//	Pixel LUT Address Generator
always@(posedge iCLK or negedge iRST_N)
begin
if(!iRST_N)
oRequest	<=	0;
else
begin
if(	H_Cont>=X_START-2 && H_Cont<X_START+H_SYNC_ACT-2 &&
V_Cont>=Y_START && V_Cont<Y_START+V_SYNC_ACT )
oRequest	<=	1;
else
oRequest	<=	0;
end
end

//	H_Sync Generator, Ref. 40 MHz Clock
always@(posedge iCLK or negedge iRST_N)
begin
if(!iRST_N)
begin
H_Cont		<=	0;
mVGA_H_SYNC	<=	0;
end
else
begin
//	H_Sync Counter
if( H_Cont < H_SYNC_TOTAL )
H_Cont	<=	H_Cont+1;
else
H_Cont	<=	0;
//	H_Sync Generator
if( H_Cont < H_SYNC_CYC )
mVGA_H_SYNC	<=	0;
else
mVGA_H_SYNC	<=	1;
end
end

//	V_Sync Generator, Ref. H_Sync
always@(posedge iCLK or negedge iRST_N)
begin
if(!iRST_N)
begin
V_Cont		<=	0;
mVGA_V_SYNC	<=	0;
end
else
begin
//	When H_Sync Re-start
if(H_Cont==0)
begin
//	V_Sync Counter
if( V_Cont < V_SYNC_TOTAL )
V_Cont	<=	V_Cont+1;
else
V_Cont	<=	0;
//	V_Sync Generator
if(	V_Cont < V_SYNC_CYC )
mVGA_V_SYNC	<=	0;
else
mVGA_V_SYNC	<=	1;
end
end
end

endmodule
