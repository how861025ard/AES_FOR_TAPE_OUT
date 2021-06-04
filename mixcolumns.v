module mixcolums(
	input [7:0] a,b,c,d,
	output [7:0] w,x,y,z
);
	
	wire [7:0] f0, f1, f2, f3, g0, g1, g2, g3;
	assign f0 = a ^ b;
	assign f1 = b ^ c;
	assign f2 = c ^ d;
	assign f3 = d ^ a;
	assign g0 = xtime(f0);
	assign g1 = xtime(f1);
	assign g2 = xtime(f2);
	assign g3 = xtime(f3);
	assign w = g0 ^ b ^ f2;
	assign x = g1 ^ c ^ f3;
	assign y = g2 ^ d ^ f0;
	assign z = g3 ^ a ^ f1;
	
	function [7:0] xtime;
		input [7:0] in;
		xtime = in[7] ? {in[6:0], 1'b0} ^ 8'h1b : {in[6:0], 1'b0};
	endfunction
		
endmodule