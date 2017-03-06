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
