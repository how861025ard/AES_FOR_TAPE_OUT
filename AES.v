module AES(
	input clk, reset, valid, 
	input [7:0] PT, KEY,
	output reg ct_valid, ready,
	output reg [7:0] CT
);

	localparam GET_PT_AND_KEY = 2'd0, ENCRYPTING = 2'd1, OUTPUT_CT = 2'd2, SET_READY_CT_VALID = 2'd3;
	
	reg [1:0] state, next_state;
	reg [7:0] state_arr [0:15];
	reg [7:0] key [0:15];
	reg [3:0] input_output_cnt;
	reg [3:0] encrypt_cnt;
	
	integer k, l, m, n, p ,q;
	wire [7:0] sbox_out_arr [0:15];
	reg [7:0] shiftrows_out_arr [0:15];
	wire [7:0] mixcolums_out_arr [0:15];
	wire [7:0] key_expansion [0:15];
	wire [7:0] rotword_out [12:15];
	wire [7:0] subword_out [12:15];
	wire [7:0] rcon [0:10];
	
	assign rotword_out[12] = key[13];//rotword
	assign rotword_out[13] = key[14];
	assign rotword_out[14] = key[15];
	assign rotword_out[15] = key[12];
		
	genvar o;
	generate
		for(o = 12; o < 16; o = o + 1)begin : sbox_1//subword
			sbox m_sbox_key(rotword_out[o], subword_out[o]);
		end
	endgenerate
	
	assign key_expansion[0] = subword_out[12] ^ rcon[encrypt_cnt] ^ key[0];
	assign key_expansion[1] = subword_out[13] ^ key[1];
	assign key_expansion[2] = subword_out[14] ^ key[2];
	assign key_expansion[3] = subword_out[15] ^ key[3];
	assign key_expansion[4] = key_expansion[0] ^ key[4];
	assign key_expansion[5] = key_expansion[1] ^ key[5];
	assign key_expansion[6] = key_expansion[2] ^ key[6];
	assign key_expansion[7] = key_expansion[3] ^ key[7];
	assign key_expansion[8] = key_expansion[4] ^ key[8];
	assign key_expansion[9] = key_expansion[5] ^ key[9];
	assign key_expansion[10] = key_expansion[6] ^ key[10];
	assign key_expansion[11] = key_expansion[7] ^ key[11];
	assign key_expansion[12] = key_expansion[8] ^ key[12];
	assign key_expansion[13] = key_expansion[9] ^ key[13];
	assign key_expansion[14] = key_expansion[10] ^ key[14];
	assign key_expansion[15] = key_expansion[11] ^ key[15];
	
	always@(posedge clk)
		if(reset) state <= GET_PT_AND_KEY;
		else state <= next_state;

	always@(*)begin
		case(state)
			GET_PT_AND_KEY : begin
				next_state = (input_output_cnt == 4'd15) ? ENCRYPTING : GET_PT_AND_KEY;
			end
			ENCRYPTING : begin
				next_state = (encrypt_cnt == 4'd10) ? OUTPUT_CT : ENCRYPTING;
			end
			OUTPUT_CT : begin
				next_state = (input_output_cnt == 4'd15) ? SET_READY_CT_VALID : OUTPUT_CT;
			end
			SET_READY_CT_VALID : 
				next_state = GET_PT_AND_KEY;
		endcase
	end

	always@(posedge clk)begin
		if(reset)begin
			input_output_cnt <= 4'd0;
			encrypt_cnt <= 4'd0;
			ct_valid <= 1'd0;
			ready <= 1'd1;
			CT <= 8'd0;
			for(p = 0; p < 16; p = p + 1)
				state_arr[p] <= 8'd0;
			for(q = 0; q < 16; q = q + 1)
				key[q] <= 8'd0;
		end
		else
			case(state)
				GET_PT_AND_KEY : begin
					if(valid)begin
						ready <= 1'd0;
						state_arr[input_output_cnt] <= PT;
						key[input_output_cnt] <= KEY;
						input_output_cnt <= input_output_cnt + 4'd1;
					end
				end
				ENCRYPTING : begin
					if(encrypt_cnt == 4'd0)//first round
						for(k = 0; k < 16; k = k + 1)
							state_arr[k] <= state_arr[k] ^ key[k];
					else if(encrypt_cnt == 4'd10)begin
						for(n = 0; n < 16; n = n + 1)
							state_arr[n] <= shiftrows_out_arr[n] ^ key_expansion[n];
					end
					else begin
						for(l = 0; l < 16; l = l + 1)
							key[l] <= key_expansion[l];
						for(m = 0; m < 16; m = m + 1)
							state_arr[m] <= mixcolums_out_arr[m] ^ key_expansion[m];
					end
					encrypt_cnt <= (encrypt_cnt == 4'd10)? 4'd0 : encrypt_cnt + 4'd1;
				end
				OUTPUT_CT : begin
					ct_valid <= 1'd1;
					CT <= state_arr[input_output_cnt];
					input_output_cnt <= input_output_cnt + 4'd1;
				end
				SET_READY_CT_VALID : begin
					ct_valid <= 1'd0;
					ready <= 1'd1;
				end
			endcase
	end
	
	genvar i;
	generate//sbox
		for(i = 0; i < 16; i = i + 1)begin : sbox_0
			sbox m_sbox(state_arr[i], sbox_out_arr[i]);
		end
	endgenerate		
			
	always@(*)begin//shiftrows
		shiftrows_out_arr[0] = sbox_out_arr[0];
		shiftrows_out_arr[1] = sbox_out_arr[5];
		shiftrows_out_arr[2] = sbox_out_arr[10];
		shiftrows_out_arr[3] = sbox_out_arr[15];
		shiftrows_out_arr[4] = sbox_out_arr[4];
		shiftrows_out_arr[5] = sbox_out_arr[9];
		shiftrows_out_arr[6] = sbox_out_arr[14];
		shiftrows_out_arr[7] = sbox_out_arr[3];
		shiftrows_out_arr[8] = sbox_out_arr[8];
		shiftrows_out_arr[9] = sbox_out_arr[13];
		shiftrows_out_arr[10] = sbox_out_arr[2];
		shiftrows_out_arr[11] = sbox_out_arr[7];
		shiftrows_out_arr[12] = sbox_out_arr[12];
		shiftrows_out_arr[13] = sbox_out_arr[1];
		shiftrows_out_arr[14] = sbox_out_arr[6];
		shiftrows_out_arr[15] = sbox_out_arr[11];
	end
	
	genvar j;
	generate//mixcolums
		for(j = 0; j < 16; j = j + 4)begin : mixcolums_0
			mixcolums m_mixcolums(shiftrows_out_arr[j], shiftrows_out_arr[j+1], shiftrows_out_arr[j+2], shiftrows_out_arr[j+3],
								  mixcolums_out_arr[j], mixcolums_out_arr[j+1], mixcolums_out_arr[j+2], mixcolums_out_arr[j+3]);
		end
	endgenerate
	
	assign rcon[0] = 8'h00;
	assign rcon[1] = 8'h01;
    assign rcon[2] = 8'h02;
    assign rcon[3] = 8'h04;
    assign rcon[4] = 8'h08;
    assign rcon[5] = 8'h10;
    assign rcon[6] = 8'h20;
    assign rcon[7] = 8'h40;
    assign rcon[8] = 8'h80;
    assign rcon[9] = 8'h1b;
    assign rcon[10] = 8'h36;
	
endmodule