reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;

wire [31:0] csr_do;

initial begin
  csr_a <= 14'b0;
  csr_we <= 1'b0;
  csr_di <= 32'b0;
end

task csrwrite;
input [13:0] address;
input [31:0] data;
begin
	csr_a = address;
	csr_we = 1'b1;
	csr_di = data;
  // Wait one clock
	waitclock;
	$display("csr Write: %x=%x", address, data);
	csr_a = 14'hx;
	csr_di = 1'b0;
	csr_we = 1'b0;
end
endtask

task csrread;
input [13:0] address;
begin
	csr_a = address;
  // Wait one clock
	waitclock;
	$display("csr Read: %x=%x", address, csr_do);
	csr_a = 14'hx;
end
endtask
