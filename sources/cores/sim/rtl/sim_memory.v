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

task mpumeminit;
reg [31:0] m [255:0];
integer i;
begin
  $readmemh({`__DIR__,"/mpu.hex"}, m, 0, 255);
  for (i = 0; i < 64; i = i + 1) begin
    $display("writing m[0x%x] = %x double word in mpu memory", i << 2, m[i]);
    wbwrite(i << 2, m[i]);
  end
end
endtask

task mpumeminittest;
integer j;
integer i;
begin
  for (i = 0; i < 64; i = i + 2) begin
    wbwrite(i << 2, 32'h10325476);
    wbwrite((i + 1) << 2, 32'h98badcfe);
  end
end
endtask
