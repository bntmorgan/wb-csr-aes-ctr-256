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

`timescale 1ns/10ps

module main();

`include "sim.v"
`include "sim_csr.v"
`include "sim_wb.v"
`include "aes_ctr_256.vh"

/**
 * Top module signals
 */

// Inputs

// Outputs
wire irq;

/**
 * Tested components
 */
aes_top aes (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .wb_adr_i(wb_adr_i),
  .wb_dat_o(wb_dat_o),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_ack_o(wb_ack_o),
  .wb_we_i(wb_we_i),
  .irq(irq)
);

/**
 * Simulation
 */

integer i;
reg [31:0] j;
initial begin

for (i = 0; i < 4; i++) begin
  // Wishbone read
  $dumpvars(0,main.aes.read_m_doa[i]);
  $dumpvars(0,main.aes.read_m_wea[i]);
  $dumpvars(0,main.aes.read_m_dia[i]);
  $dumpvars(0,main.aes.read_m_addra[i]);

  // AES read
  $dumpvars(0,main.aes.read_m_dob[i]);
  $dumpvars(0,main.aes.read_m_web[i]);
  $dumpvars(0,main.aes.read_m_dib[i]);
  $dumpvars(0,main.aes.read_m_addrb[i]);

  // Wishbone write
  $dumpvars(0,main.aes.write_m_doa[i]);
  $dumpvars(0,main.aes.write_m_wea[i]);
  $dumpvars(0,main.aes.write_m_dia[i]);
  $dumpvars(0,main.aes.write_m_addra[i]);

  // AES write
  $dumpvars(0,main.aes.write_m_dob[i]);
  $dumpvars(0,main.aes.write_m_web[i]);
  $dumpvars(0,main.aes.write_m_dib[i]);
  $dumpvars(0,main.aes.write_m_addrb[i]);
end;

  waitclock;

  sys_rst <= 1'b1;

  waitnclock(8);

  sys_rst <= 1'b0;

  // Test wishbone

  // Clair
  $display("Écriture du clair");
  wbwrite(32'h00000000, 32'h676E6953);
  wbwrite(32'h00000004, 32'h6220656C);
  wbwrite(32'h00000008, 32'h6B636F6C);
  wbwrite(32'h0000000c, 32'h67736D20);

  // Lecture clair
  $display("Lecture du clair");
  wbread(32'h00000000);
  wbread(32'h00000004);
  wbread(32'h00000008);
  wbread(32'h0000000c);

  // Test csr

  // Écriture de la session key

  $display("Écriture de la clé de session");


  csrwrite(`AES_CSR_KEY0, 32'hF2EF6B77);
  csrwrite(`AES_CSR_KEY1, 32'h6FB01D85);
  csrwrite(`AES_CSR_KEY2, 32'h42058A4C);
  csrwrite(`AES_CSR_KEY3, 32'h6C6F69C8);
  csrwrite(`AES_CSR_KEY4, 32'h1EAF816A);
  csrwrite(`AES_CSR_KEY5, 32'hD3B496EC);
  csrwrite(`AES_CSR_KEY6, 32'h89D6C17F);
  csrwrite(`AES_CSR_KEY7, 32'h04C1C1E6);

  // Nonce

  $display("Écriture du nonce");
  csrwrite(`AES_CSR_NONC, 32'h60000000);

  // Initialization Vector

  csrwrite(`AES_CSR_IV_0, 32'hC97256DB);
  csrwrite(`AES_CSR_IV_1, 32'hB2F0A87A);

  // Start

  $display("Lancement du core");
  csrwrite(`AES_CSR_CTRL, 32'h03);

  waitnclock('h300);

  // Clear the interrupts and stop irqs
  $display("Exctinction du core");
  csrwrite(`AES_CSR_STAT, 32'hff);
  csrwrite(`AES_CSR_CTRL, 32'h00);

  // Read the encrypted data
  $display("DEBUT CHIFFRÉ!");
  for (i = 'h1000; i < 'h1010 ; i = i + 4) begin
    wbread(i);
  end
  $display("FIN CHIFFRÉ!");

  $finish;
end

endmodule
