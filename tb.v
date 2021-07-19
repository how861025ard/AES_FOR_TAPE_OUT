`timescale 1ns/10ps
`define CLK_period 10

module tb;

	reg clk, reset, valid;
	reg [7:0] PT, KEY;
	wire ct_valid;
	wire [7:0] CT;
	wire ready;
	
	AES m_aes( .clk(clk), .reset(reset), .valid(valid), .PT(PT), .KEY(KEY), .ct_valid(ct_valid), .CT(CT), .ready(ready));
	
	reg [7:0] pt_mem [1:16];
	reg [7:0] ct_mem_pat [1:16];
	reg [7:0] key_mem [1:16];
	
	`ifdef SDF
	initial $sdf_annotate("aes.sdf", m_aes);
	`endif
	
	initial $readmemh("./pt.dat", pt_mem);
	initial $readmemh("./ct.dat", ct_mem_pat);
	initial $readmemh("./key.dat", key_mem);
	initial begin
	$fsdbDumpfile("aes.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA;
	end


	initial clk = 1'b0;
	always begin #(`CLK_period/2.0) clk = ~clk; end
	
	initial begin
		#0 reset = 1'b0;
		#`CLK_period reset = 1'b1;
		#(`CLK_period*2) reset = 1'b0;
	end
	
	integer i;
	reg [4:0]ct_cnt = 1;
	reg flag = 1;
	
	initial begin
		#0 valid = 1'b0;
		i = 1;
		#(`CLK_period*5);
		@(negedge clk) valid = 1'b1;
			PT = pt_mem[i];
			KEY = key_mem[i];
		for (i = 2;i <= 16; i = i + 1)
			@(negedge clk) begin PT = pt_mem[i]; KEY = key_mem[i]; end
		@(negedge clk) valid = 1'b0;
		PT = 8'b0;
		KEY = 8'b0;
	   wait(ct_valid);
	   while(ct_cnt != 16)begin
			if(ct_valid)@(negedge clk)begin
				if(CT != ct_mem_pat[ct_cnt]) flag = 0;
				ct_cnt = ct_cnt + 1;
				$display("%d",ct_cnt);
			end
		end
		if(flag)
			$display("correct");
		else
			$display("not correct");
		
		#5000 $stop;
	end
	

endmodule