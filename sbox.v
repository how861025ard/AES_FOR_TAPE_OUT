module sbox(
	input [7:0] sbox_in,
	output [7:0] sbox_out
);
	wire [3:0] iso_out_msb, iso_out_lsb, mul_inv_out, iso_out_msb_xor_iso_out_lsb;
	
	assign {iso_out_msb, iso_out_lsb} = isomorphic(sbox_in);
	assign iso_out_msb_xor_iso_out_lsb = iso_out_msb ^ iso_out_lsb;
	assign mul_inv_out = mul_inv(mul_constant_squarer(iso_out_msb) ^ (mul_4(iso_out_msb_xor_iso_out_lsb, iso_out_lsb)));
	
	assign sbox_out = aff_trans_inv_isomorphic({mul_4(iso_out_msb, mul_inv_out), mul_4(iso_out_msb_xor_iso_out_lsb, mul_inv_out)});
	
	function [7:0] isomorphic;
		input [7:0] q;
		reg [7:0] iso;
		reg q7_q5, q7_q6, q6_q1, q4_q3, q2_q1;
		begin
			q7_q5 = q[7] ^ q[5];
			q7_q6 = q[7] ^ q[6];
			q6_q1 = q[6] ^ q[1];
			q4_q3 = q[4] ^ q[3];
			q2_q1 = q[2] ^ q[1];
			iso[7] = q7_q5;
			iso[6] = q7_q6 ^ q4_q3 ^ q2_q1;
			iso[5] = q7_q5 ^ (q[3] ^ q[2]); 
			iso[4] = q7_q5 ^ q[3] ^ q2_q1; 
			iso[3] = q7_q6 ^ q2_q1;
			iso[2] = q[7] ^ q4_q3 ^ q2_q1;
			iso[1] = q[4] ^ q6_q1;
			iso[0] = q6_q1 ^ q[0];
			isomorphic = {iso[7], iso[6], iso[5], iso[4], iso[3], iso[2], iso[1], iso[0]};
		end
	endfunction
			
	function [7:0] inv_isomorphic;
		input [7:0] q;
		reg [7:0] inv_iso;
		reg q6_q5, q6_q2, q5_q4, q4_q3, q2_q1;
		begin
			q6_q5 = q[6] ^ q[5];
			q6_q2 = q[6] ^ q[2];
			q5_q4 = q[5] ^ q[4];
			q4_q3 = q[4] ^ q[3];
			q2_q1 = q[2] ^ q[1];
			inv_iso[7] = q6_q5 ^ (q[7] ^ q[1]);
			inv_iso[6] = q6_q2;
			inv_iso[5] = q6_q5 ^ q[1]; 
			inv_iso[4] = q6_q5 ^ q[4] ^ q2_q1; 
			inv_iso[3] = q[5] ^ q4_q3 ^ q2_q1;
			inv_iso[2] = q[7] ^ q4_q3 ^ q2_q1;
			inv_iso[1] = q5_q4;
			inv_iso[0] = q6_q2 ^ q5_q4 ^ q[0];
			inv_isomorphic = {inv_iso[7], inv_iso[6], inv_iso[5], inv_iso[4], inv_iso[3], inv_iso[2], inv_iso[1], inv_iso[0]};
		end
	endfunction
	
	function [3:0] squarer;
		input [3:0] q;
		squarer = {q[3], q[3] ^ q[2], q[2] ^ q[1], q[3] ^ q[1] ^ q[0]};
	endfunction
	
	function [3:0] mul_constant;
		input [3:0] q;
		reg q2_q0;
		begin
			q2_q0 = q[2] ^ q[0];
			mul_constant = {q2_q0, q2_q0 ^ (q[3] ^ q[1]), q[3], q[2]};
		end
	endfunction
	
	function [1:0] mul_2;
		input [1:0] q, w;
		reg q0_and_w0;
		begin
			q0_and_w0 = q[0] & w[0];
			mul_2 = {((q[1] ^ q[0]) & (w[1] ^ w[0])) ^ q0_and_w0 , (q[1] & w[1]) ^ q0_and_w0}; 
		end
	endfunction
	
	function [1:0] mul_constant_mul_4;
		input [1:0] q;
		mul_constant_mul_4 = {q[1] ^ q[0], q[1]};
	endfunction
	
	function [3:0] mul_4;
		input [3:0] q, w;
		reg [1:0] temp;
		begin
			temp = mul_2(q[1:0], w[1:0]);
			mul_4 = {temp ^ mul_2(q[3:2] ^ q[1:0], w[3:2] ^ w[1:0]), temp ^ mul_constant_mul_4(mul_2(q[3:2], w[3:2]))};
		end
	endfunction
	
	function [3:0] mul_inv;
		input [3:0] q;
		reg q3_q2_q1, q3_q2_q0, q3_q1_q0, q3_q0, q2_q1;
		begin
			q3_q2_q1 = q[3] & q[2] & q[1];
			q3_q2_q0 = q[3] & q[2] & q[0];
			q3_q1_q0 = q[3] & q[1] & q[0];
			q3_q0 = q[3] & q[0];
			q2_q1 = q[2] & q[1];
			mul_inv = {q[3] ^ q3_q2_q1 ^ q3_q0 ^ q[2], q3_q2_q1 ^ q3_q2_q0 ^ q3_q0 ^ q[2] ^ q2_q1, q[3] ^ q3_q2_q1 ^ q3_q1_q0 ^ q[2] ^ (q[2] & q[0]) ^q[1],
			           q3_q2_q1 ^ q3_q2_q0 ^ (q[3] & q[1]) ^ q3_q1_q0 ^ q3_q0 ^ q[2] ^ q2_q1 ^ (q[2] & q[1] & q[0]) ^ q[1] ^ q[0]};
		end
	endfunction
	
	function [7:0] aff_trans;
		input [7:0] q;
		reg q7_q6, q5_q0, q4_q3, q2_q1, q7_q6_q5_q0, q4_q3_q2_q1;
		begin
			q7_q6 = q[7] ^ q[6];
			q5_q0 = q[5] ^ q[0];
			q4_q3 = q[4] ^ q[3];
			q2_q1 = q[2] ^ q[1];
			q7_q6_q5_q0 = q7_q6 ^ q5_q0;
			q4_q3_q2_q1 = q4_q3 ^ q2_q1;
			aff_trans = {q7_q6 ^ q[5] ^ q4_q3, ~((q[6] ^ q[5]) ^ q4_q3 ^ q[2]), ~(q[5] ^ q4_q3_q2_q1), q4_q3_q2_q1 ^ q[0], (q[7] ^ q[3]) ^ q2_q1 ^ q[0],
			             q7_q6 ^ q2_q1 ^ q[0], ~(q7_q6_q5_q0 ^ q[1]), ~(q7_q6_q5_q0 ^ q[4])};
		end
	endfunction
	
	function [7:0] aff_trans_inv_isomorphic;
		input [7:0] q;
		reg q7_q2, q7_q0, q6_q5, q4_q1, q2_q0;
		begin
			q7_q2 = q[7] ^ q[2];
			q7_q0 = q[7] ^ q[0];
			q6_q5 = q[6] ^ q[5];
			q4_q1 = q[4] ^ q[1];
			q2_q0 = q[2] ^ q[0];
			aff_trans_inv_isomorphic = {q7_q2 ^	q[3], (q[7] ^ q[4]) ^ q6_q5 ^ 1'b1, q7_q2 ^ 1'b1, q7_q0 ^ q4_q1, q[1] ^ q2_q0,
			             q6_q5 ^ (q[4] ^ q[3]) ^ q2_q0, q7_q0 ^ 1'b1, q7_q0 ^ (q[1] ^ q[2]) ^ q[6] ^ 1'b1};
		end
	endfunction

	function [3:0] mul_constant_squarer;
		input [3:0] q;
		begin
			mul_constant_squarer = {q[2] ^ q[1] ^ q[0], q[3] ^ q[0], q[3], q[3] ^ q[2]};
		end
	endfunction
endmodule