

module fill
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		SW,
		KEY,							// On Board Keys
		// The ports below are for the VGA output.  
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;					
	input [3:0] SW;
	
	// Declare your inputs and outputs here
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = SW[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire right, left, up, down;
	wire enable;
	
	assign colour = 3'b111;

	
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(SW[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	
	control u1 (.clock(CLOCK_50), 
					.resetn(SW[0]), 
					.key_in(~KEY[3:0]), // too out negate 
					.right(right), 
					.left(left), 
					.up(up), 
					.down(down));
					
					
	datapath u2 (.clock(CLOCK_50),
					 .resetn(SW[0]), 
					 .right(right), 
					 .left(left), 
					 .up(up), 
					 .down(down), 
					 .xpos(x), 
					 .ypos(y));
	
	RateDivider4 FourSec (enable,CLOCK_50);
	
endmodule

module control(input clock, resetn, input [3:0] key_in,
					output reg  right, left, up, down, black);
					
reg move, signal, pixel;
reg[4:0] current_state, next_state;

localparam 		S_BLACK      = 3'd0,
               S_MOVE       = 3'd1, 
					S_IDLE		 = 3'd2;
									
always @(*)
    begin: state_table 
			case (current_state)
			S_BLACK:   next_state = (key_in[0] || key_in[1] || key_in[2] || key_in[3]) ? S_MOVE : S_BLACK;
			S_MOVE: 	  next_state = (key_in[0] || key_in[1] || key_in[2] || key_in[3]) ? S_MOVE : S_IDLE ;
			S_IDLE:	  next_state = (key_in[0] || key_in[1] || key_in[2] || key_in[3]) ? S_MOVE : S_IDLE;
			
			default:  next_state = S_BLACK;
			
			endcase
	end 
	
	
// Output logic aka all of our datapath control signals
always @(posedge clock)
	begin: inputs 
		if (key_in[0] && key_in[1])  //right-down
			begin
				signal = 1'b1; 
				right = 1'b1;
				left = 1'b0;
				up = 1'b0;
				down = 1'b1;
				move = 1'b1;
			end
		else if (key_in[0] && key_in[2])  //right-up
			begin
				signal = 1'b1; 
				right = 1'b1;
				left = 1'b0;
				up = 1'b1;
				down = 1'b0;
				move = 1'b1;
			end
		else if (key_in[0])  //right
			begin
				signal = 1'b1; 
				right = 1'b1;
				left = 1'b0;
				up = 1'b0;
				down = 1'b0;
				move = 1'b1;
			end
		else if (key_in[3] && key_in[1]) //left-down
			begin
				signal = 1'b1; 
				right = 1'b0;
				left = 1'b1;
				up = 1'b0;
				down = 1'b1;
				move = 1'b1;
			end
		else if (key_in[3] && key_in[2]) //left-up
			begin
				signal = 1'b1; 
				right = 1'b0;
				left = 1'b1;
				up = 1'b1;
				down = 1'b0;
				move = 1'b1;
			end
		else if (key_in[3]) //left
			begin
				signal = 1'b1; 
				right = 1'b0;
				left = 1'b1;
				up = 1'b0;
				down = 1'b0;
				move = 1'b1;
			end
		else if (key_in[1]) //down
			begin
				signal = 1'b1; 
				right = 1'b0;
				left = 1'b0;
				up = 1'b0;
				down = 1'b1;
				move = 1'b1;
			end
		else if (key_in[2]) //up 
			begin
				signal = 1'b1; 
				right = 1'b0;
				left = 1'b0;
				up = 1'b1;
				down = 1'b0;
				move = 1'b1;
			end
		else
			begin 
				signal = 1'b0; 
				right = 1'b0;
				left = 1'b0;
				up = 1'b0;
				down = 1'b0;
				move = 1'b0;
			end
end


always @(*)
	begin: enable_signals
        // By default make all our signals 0 to avoid latches
      //move = 1'b0; if set to 0, move is 0 for right
		//newcolour=colour;
		
		case (current_state)
			S_BLACK: begin 
				move = 1'b0;
				//pixel <= pixel + 1'b1; 
			end
			S_MOVE: begin
				move = 1'b1;
			end
			S_IDLE: begin 
				move = 1'b0;
			end 
		endcase
	end
	
 always@(posedge clock)
	begin: state_FFs
		if(!resetn)  
			begin
			current_state <= S_BLACK;
			end
		else if (key_in[0] || key_in[1] || key_in[2] || key_in[3])
			begin
			current_state <= S_MOVE; 
			end
		else
			begin
         current_state <= next_state; 
			end
	end
	
endmodule

module datapath (input clock, resetn, left, right, up, down, output reg [7:0] xpos, ypos);

reg [7:0] originalX, originalY, xcount, ycount; 

initial begin
	xcount = 8'b00000000;
	ycount = 8'b00000000;
	originalX = 8'b00000000;
	originalY = 8'b00000000;
end

always @(posedge clock) 
	begin
	if (!resetn)
		begin
		xcount = 8'b00000000;
		ycount = 8'b00000000;
		end
	else if (right && down) //right-down
		begin
		xcount = xcount + 1'b1;
		ycount = ycount + 1'b1;
		end
	else if (right && up) //right-up
		begin
		xcount = xcount + 1'b1;
		ycount = ycount - 1'b1;
		end
	else if (right)
		begin
		xcount = xcount + 1'b1;
		end
	else if (left && down)
		begin
		xcount = xcount - 1'b1;
		ycount = ycount + 1'b1;
		end
	else if (left && up)
		begin
		xcount = xcount - 1'b1;
		ycount = ycount - 1'b1;
		end
	else if (left)
		begin
		xcount = xcount - 1'b1;
		end
	else if (up)
		begin 
		ycount = ycount - 1'b1;
		end 
	else if (down) 
		begin
		ycount = ycount + 1'b1;
		end 
	else 
		begin
		xcount = xcount + 1'b0;
		ycount = ycount + 1'b0;
		end
	end
	
always @(*)
	begin 
	xpos = originalX + xcount; 
	ypos = originalY + ycount; 
	end
	
	
endmodule 

module RateDivider4 (q,clock);

input clock;
output reg q;
integer ctr = 0;

always @(posedge clock)
begin
	if (ctr == (50000000 / 4 - 1))
	begin
		q <= 1;
		ctr = 0;
		end
	
	else
		begin
		ctr <= ctr + 1;
		q <= 0;
		end
end

endmodule

