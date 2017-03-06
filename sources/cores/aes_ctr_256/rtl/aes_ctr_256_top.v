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

`include "aes_ctr_256.vh"

module aes_top #(
  parameter csr_addr = 4'h0
) (
  input sys_clk,
  input sys_rst,

  // CSR bus
  input [13:0] csr_a,
  input csr_we,
  input [31:0] csr_di,
  output reg [31:0] csr_do,

  // Wishbone bus
  input [31:0] wb_adr_i,
  output reg [31:0] wb_dat_o,
  input [31:0] wb_dat_i,
  input [3:0] wb_sel_i,
  input wb_stb_i,
  input wb_cyc_i,
  output reg wb_ack_o,
  input wb_we_i,

  // IRQ
  output irq
);

// System
wire csr_selected = csr_a[13:10] == csr_addr;

// IRQs
reg irq_en;
assign irq = irq_en & (event_end);

// Ctrls
reg aes_start;

// Events
reg event_end;

// DATA
reg [255:0] key; // The AES 256 bit key
reg [31:0] nonce;
reg [63:0] iv;

task init;
begin
  irq_en <= 1'b0;
  event_end <= 1'b0;
  aes_start <= 1'b0;
  csr_do <= 32'd0;
  key <= 256'b0;
  nonce <= 32'b0;
  iv <= 64'b0;
end
endtask

// CSR state machine

always @(posedge sys_clk) begin
  if (sys_rst) begin
    init;
  end else begin
    // CSR
    csr_do <= 32'd0;
    aes_start <= 1'b0;
    if (csr_selected) begin
      case (csr_a[9:0])
        `AES_CSR_STAT: csr_do <= {31'b0, event_end};
        `AES_CSR_CTRL: csr_do <= {30'b0, aes_start, irq_en};
        `AES_CSR_KEY0: csr_do <= key[ 31:  0];
        `AES_CSR_KEY1: csr_do <= key[ 63: 32];
        `AES_CSR_KEY2: csr_do <= key[ 95: 64];
        `AES_CSR_KEY3: csr_do <= key[127: 96];
        `AES_CSR_KEY4: csr_do <= key[159:128];
        `AES_CSR_KEY5: csr_do <= key[191:160];
        `AES_CSR_KEY6: csr_do <= key[223:192];
        `AES_CSR_KEY7: csr_do <= key[255:224];
        `AES_CSR_NONC: csr_do <= nonce;
        `AES_CSR_IV_0: csr_do <= iv[63:32];
        `AES_CSR_IV_1: csr_do <= iv[95:64];
      endcase
      if (csr_we) begin
        case (csr_a[9:0])
          `AES_CSR_STAT: begin
            /* write one to clear */
            if(csr_di[0])
              event_end <= 1'b0;
          end
          `AES_CSR_CTRL: begin
            irq_en <= csr_di[0];
            aes_start <= csr_di[1];
          end
          `AES_CSR_KEY0: key[ 31:  0] <= csr_di;
          `AES_CSR_KEY1: key[ 63: 32] <= csr_di;
          `AES_CSR_KEY2: key[ 95: 64] <= csr_di;
          `AES_CSR_KEY3: key[127: 96] <= csr_di;
          `AES_CSR_KEY4: key[159:128] <= csr_di;
          `AES_CSR_KEY5: key[191:160] <= csr_di;
          `AES_CSR_KEY6: key[223:192] <= csr_di;
          `AES_CSR_KEY7: key[255:224] <= csr_di;
          `AES_CSR_NONC: nonce <= csr_di;
          `AES_CSR_IV_0: iv[31: 0] <= csr_di;
          `AES_CSR_IV_1: iv[63:32] <= csr_di;
        endcase
      end
    end
    // Events !
    if (aes_end == 1'b1) begin
      event_end <= 1'b1;
    end
  end
end

// State machine
reg sm;
// State initialized by the nonce and incremented
reg [127:0] state;
// Counter for genereate 256 states for the 256 128 bit words
reg [7:0] cpt_state;
// Event end communication
reg aes_end;

// AES core
wire [127:0] out;
wire [127:0] out_le;
wire [255:0] key_be;

// Memory interface is 128 bit wide !!!
reg [7:0] mem_read_a;
wire [127:0] mem_read_dr;

reg [7:0] mem_write_a;
wire [127:0] mem_write_dw = mem_read_dr ^ out_le;
reg mem_write_we;

task init_aes;
begin
  sm <= `AES_STATE_IDLE;
  mem_read_a <= 8'b0;
  mem_write_a <= 8'b0;
  mem_write_we <= 'b0;
  cpt_state <= 8'b0;
  aes_end <= 1'b0;
  state <= 128'b0;
end
endtask

//
// Caution !
// The tiny AES core byte order is reversed
// see https://tools.ietf.org/html/rfc3686 for AES documentation
//
assign key_be = {
  key[  7:  0],
  key[ 15:  8],
  key[ 23: 16],
  key[ 31: 24],
  key[ 39: 32],
  key[ 47: 40],
  key[ 55: 48],
  key[ 63: 56],
  key[ 71: 64],
  key[ 79: 72],
  key[ 87: 80],
  key[ 95: 88],
  key[103: 96],
  key[111:104],
  key[119:112],
  key[127:120],
  key[135:128],
  key[143:136],
  key[151:144],
  key[159:152],
  key[167:160],
  key[175:168],
  key[183:176],
  key[191:184],
  key[199:192],
  key[207:200],
  key[215:208],
  key[223:216],
  key[231:224],
  key[239:232],
  key[247:240],
  key[255:248]
};
assign out_le = {
  out[  7:  0],
  out[ 15:  8],
  out[ 23: 16],
  out[ 31: 24],
  out[ 39: 32],
  out[ 47: 40],
  out[ 55: 48],
  out[ 63: 56],
  out[ 71: 64],
  out[ 79: 72],
  out[ 87: 80],
  out[ 95: 88],
  out[103: 96],
  out[111:104],
  out[119:112],
  out[127:120]
};
// AES state machine
always @(posedge sys_clk) begin
  if (sys_rst) begin
    init_aes;
  end else begin
    aes_end <= 1'b0;
    mem_write_we <= 1'b0;
    if (sm == `AES_STATE_RUN) begin
      // This is the end !
      if (cpt_state == 8'hff && mem_read_a == 8'hff) begin
        sm <= `AES_STATE_IDLE;
        aes_end <= 1'b1;
        mem_write_a <= mem_write_a + 1'b1;
        mem_write_we <= 1'b1;
      end else begin
        // We increment the state to generate AES output
        if (cpt_state < 8'hff) begin
          cpt_state <= cpt_state + 1'b1;
          // Counter is big endian but tiny aes core byte order is reversed
          state[31:0] <= state[31:0] + 1'b1;
        end
        // AES out is now ready to use
        if (cpt_state >= 8'h1c) begin
          mem_read_a <= mem_read_a + 1'b1;
          mem_write_we <= 1'b1;
        end
        // We have written the first 128 bits in the memory we can increment the
        // write address
        if (cpt_state >= 8'h1d) begin
          mem_write_a <= mem_write_a + 1'b1;
        end
      end
    end else begin
      init_aes;
      if (aes_start == 1'b1) begin
        sm <= `AES_STATE_RUN;
        state <= {
          // Nonce
          nonce[7:0],
          nonce[15:8],
          nonce[23:16],
          nonce[31:24],
          // IV
          iv[7:0],
          iv[15:8],
          iv[23:16],
          iv[31:24],
          iv[39:32],
          iv[47:40],
          iv[55:48],
          iv[63:56],
          // Counter is big endian but tiny aes core byte order is reversed
          32'h00000001
        };
      end
    end
  end
end

initial begin
  init;
  init_aes;
end

// AES core
aes_256 aes_256 (
  .clk(sys_clk),
  .state(state),
  .key(key_be),
  .out(out)
);

// Memories

wire wb_en = wb_cyc_i & wb_stb_i;

// Read
wire [31:0] read_m_doa [3:0];
wire [31:0] read_m_dia [3:0];
wire [7:0] read_m_addra [3:0];
wire [3:0] read_m_wea [3:0];

wire [31:0] read_m_dob [3:0];
wire [31:0] read_m_dib [3:0];
wire [7:0] read_m_addrb [3:0];
wire [3:0] read_m_web [3:0];

// Write
wire [31:0] write_m_doa [3:0];
wire [31:0] write_m_dia [3:0];
wire [7:0] write_m_addra [3:0];
wire [3:0] write_m_wea [3:0];

wire [31:0] write_m_dib [3:0];
wire [31:0] write_m_dob [3:0];
wire [7:0] write_m_addrb [3:0];
wire [3:0] write_m_web [3:0];

genvar ram_index;
generate for (ram_index=0; ram_index < 4; ram_index=ram_index+1)
begin: gen_ram
  RAMB36 #(
    .WRITE_WIDTH_A(36),
    .READ_WIDTH_A(36),
    .WRITE_WIDTH_B(36),
    .READ_WIDTH_B(36),
    .DOA_REG(0),
    .DOB_REG(0),
    .SIM_MODE("SAFE"),
    .INIT_A(9'h000),
    .INIT_B(9'h000),
    .WRITE_MODE_A("WRITE_FIRST"),
    .WRITE_MODE_B("WRITE_FIRST")
  ) read_ram (
    .DIA(read_m_dia[ram_index]),
    .DIPA(4'h0),
    .DOA(read_m_doa[ram_index]),
    .ADDRA({3'b0, read_m_addra[ram_index], 5'b0}),
    .WEA(read_m_wea[ram_index]),
    .ENA(1'b1),
    .CLKA(sys_clk),
    
    .DIB(read_m_dib[ram_index]),
    .DIPB(4'h0),
    .DOB(read_m_dob[ram_index]),
    .ADDRB({3'b0, read_m_addrb[ram_index], 5'b0}),
    .WEB(read_m_web[ram_index]),
    .ENB(1'b1),
    .CLKB(sys_clk),

    .REGCEA(1'b0),
    .REGCEB(1'b0),
    
    .SSRA(1'b0),
    .SSRB(1'b0)
  );
  RAMB36 #(
    .WRITE_WIDTH_A(36),
    .READ_WIDTH_A(36),
    .WRITE_WIDTH_B(36),
    .READ_WIDTH_B(36),
    .DOA_REG(0),
    .DOB_REG(0),
    .SIM_MODE("SAFE"),
    .INIT_A(9'h000),
    .INIT_B(9'h000),
    .WRITE_MODE_A("WRITE_FIRST"),
    .WRITE_MODE_B("WRITE_FIRST")
  ) write_ram (
    .DIA(write_m_dia[ram_index]),
    .DIPA(4'h0),
    .DOA(write_m_doa[ram_index]),
    .ADDRA({3'b0, write_m_addra[ram_index], 5'b0}),
    .WEA(write_m_wea[ram_index]),
    .ENA(1'b1),
    .CLKA(sys_clk),
    
    .DIB(write_m_dib[ram_index]),
    .DIPB(4'h0),
    .DOB(write_m_dob[ram_index]),
    .ADDRB({3'b0, write_m_addrb[ram_index], 5'b0}),
    .WEB(write_m_web[ram_index]),
    .ENB(1'b1),
    .CLKB(sys_clk),

    .REGCEA(1'b0),
    .REGCEB(1'b0),
    
    .SSRA(1'b0),
    .SSRB(1'b0)
  );
end
endgenerate

// Memory behavior

// AES core

// Read
assign read_m_addrb[0] = mem_read_a;
assign read_m_addrb[1] = mem_read_a;
assign read_m_addrb[2] = mem_read_a;
assign read_m_addrb[3] = mem_read_a;

assign mem_read_dr = {
  read_m_dob[3],
  read_m_dob[2],
  read_m_dob[1],
  read_m_dob[0]
};

assign read_m_web[0] = 4'b0;
assign read_m_web[1] = 4'b0;
assign read_m_web[2] = 4'b0;
assign read_m_web[3] = 4'b0;

assign read_m_dib[0] = 32'b0;
assign read_m_dib[1] = 32'b0;
assign read_m_dib[2] = 32'b0;
assign read_m_dib[3] = 32'b0;

// Write
assign write_m_addrb[0] = mem_write_a;
assign write_m_addrb[1] = mem_write_a;
assign write_m_addrb[2] = mem_write_a;
assign write_m_addrb[3] = mem_write_a;

assign write_m_web[0] = (mem_write_we == 1'b1) ? 4'hf : 4'h0;
assign write_m_web[1] = (mem_write_we == 1'b1) ? 4'hf : 4'h0;
assign write_m_web[2] = (mem_write_we == 1'b1) ? 4'hf : 4'h0;
assign write_m_web[3] = (mem_write_we == 1'b1) ? 4'hf : 4'h0;

assign write_m_dib[0] = mem_write_dw[31:0];
assign write_m_dib[1] = mem_write_dw[63:32];
assign write_m_dib[2] = mem_write_dw[95:64];
assign write_m_dib[3] = mem_write_dw[127:96];

// Wishbone

assign read_m_addra[0] = wb_adr_i[11:4];
assign read_m_addra[1] = wb_adr_i[11:4];
assign read_m_addra[2] = wb_adr_i[11:4];
assign read_m_addra[3] = wb_adr_i[11:4];

assign write_m_addra[0] = wb_adr_i[11:4];
assign write_m_addra[1] = wb_adr_i[11:4];
assign write_m_addra[2] = wb_adr_i[11:4];
assign write_m_addra[3] = wb_adr_i[11:4];

// Write
assign read_m_dia[0] = wb_dat_i;
assign read_m_dia[1] = wb_dat_i;
assign read_m_dia[2] = wb_dat_i;
assign read_m_dia[3] = wb_dat_i;

assign write_m_dia[0] = wb_dat_i;
assign write_m_dia[1] = wb_dat_i;
assign write_m_dia[2] = wb_dat_i;
assign write_m_dia[3] = wb_dat_i;

assign read_m_wea[0] = (wb_en & wb_we_i & ~wb_adr_i[3] & ~wb_adr_i[2] &
  ~wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign read_m_wea[1] = (wb_en & wb_we_i & ~wb_adr_i[3] &  wb_adr_i[2] &
  ~wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign read_m_wea[2] = (wb_en & wb_we_i &  wb_adr_i[3] & ~wb_adr_i[2] &
  ~wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign read_m_wea[3] = (wb_en & wb_we_i &  wb_adr_i[3] &  wb_adr_i[2] &
  ~wb_adr_i[12]) ?  wb_sel_i : 4'b0000;

assign write_m_wea[0] = (wb_en & wb_we_i & ~wb_adr_i[3] & ~wb_adr_i[2] &
   wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign write_m_wea[1] = (wb_en & wb_we_i & ~wb_adr_i[3] &  wb_adr_i[2] &
   wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign write_m_wea[2] = (wb_en & wb_we_i &  wb_adr_i[3] & ~wb_adr_i[2] &
   wb_adr_i[12]) ?  wb_sel_i : 4'b0000;
assign write_m_wea[3] = (wb_en & wb_we_i &  wb_adr_i[3] & ~wb_adr_i[2] &
   wb_adr_i[12]) ?  wb_sel_i : 4'b0000;

// Read
always @(*) begin
  if (sys_rst == 1'b1) begin
    wb_dat_o = 32'b0;
  end else begin
    // Read memory
    if (~wb_adr_i[12]) begin
      wb_dat_o = read_m_doa[wb_adr_i[3:2]];
    // Write memory
    end else begin
      wb_dat_o = write_m_doa[wb_adr_i[3:2]];
    end
  end
end

initial wb_ack_o <= 1'b0;
always @(posedge sys_clk) begin
  if(sys_rst)
    wb_ack_o <= 1'b0;
  else begin
    wb_ack_o <= 1'b0;
    if(wb_en & ~wb_ack_o)
      wb_ack_o <= 1'b1;
  end
end

endmodule
