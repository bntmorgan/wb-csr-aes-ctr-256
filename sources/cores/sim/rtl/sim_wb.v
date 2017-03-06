reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
reg [3:0] wb_sel_i;
reg wb_stb_i;
reg wb_cyc_i;
reg wb_we_i;
reg [2:0] wb_cti_i;

wire [31:0] wb_dat_o;
wire wb_ack_o;

initial begin
  wb_adr_i <= 32'b0;
  wb_dat_i <= 32'b0;
  wb_sel_i <= 4'b0;
  wb_stb_i <= 1'b0;
  wb_cyc_i <= 1'b0;
  wb_we_i <= 1'b0;
end

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_dat_i = data;
	wb_sel_i = 4'hf;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_adr_i = 32'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
 	while(~wb_ack_o) begin
 		i = i+1;
 		waitclock;
 	end
 	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
 	waitclock;
 	// wb_adr_i = 32'hx;
 	wb_adr_i = 32'h0;
 	wb_cyc_i = 1'b0;
 	wb_stb_i = 1'b0;
 	wb_we_i = 1'b0;
end
endtask

task wbcopy;
input [31:0] address_d;
input [31:0] address_s;
reg [31:0] data;
integer i;
begin
	wb_adr_i = address_s;
	wb_cti_i = 3'b000;
	wb_dat_i = 32'h0;
	wb_sel_i = 4'hf;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
  data = wb_dat_o;
	waitclock;
	$display("WB read: %x=%x acked in %d clocks", address_s, wb_dat_o, i);
	wb_adr_i = address_d;
	wb_cti_i = 3'b000;
	wb_dat_i = data;
	wb_sel_i = 4'hf;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address_d, data, i);
	wb_adr_i = 32'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread_nonblock;
input [31:0] address;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
  // wait three clocks
  waitclock;
  waitclock;
	$display("WB Read : %x=%x acked in 3 clocks", address, wb_dat_o);
	waitclock;
	// wb_adr_i = 32'hx;
	wb_adr_i = 32'h0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

//always @(*)
//begin
//  $display("-");
//  $display("wb_adr_i %x", wb_adr_i);
//  $display("wb_dat_i %x", wb_dat_i);
//  $display("wb_sel_i %x", wb_sel_i);
//  $display("wb_stb_i %x", wb_stb_i);
//  $display("wb_cyc_i %x", wb_cyc_i);
//  $display("wb_we_i %x", wb_we_i);
//  $display("wb_dat_o %x", wb_dat_o);
//  $display("wb_ack_o %x", wb_ack_o);
//end
