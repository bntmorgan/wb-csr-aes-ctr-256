/*
Copyright (C) 2015  Benoît Morgan

This file is part of wb-csr-aes-ctr-256.

wb-csr-aes-ctr-256 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

wb-csr-aes-ctr-256 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with wb-csr-aes-ctr-256.  If not, see <http://www.gnu.org/licenses/>.
*/

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
