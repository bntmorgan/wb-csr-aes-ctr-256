sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/mpu.bit)
SRC_$(d)				:= $(d)/rtl/aes_ctr_256_top.v \
	$(CORES_DIR)/tiny_aes/rtl/aes_256.v \
	$(CORES_DIR)/tiny_aes/rtl/round.v \
	$(CORES_DIR)/tiny_aes/rtl/table.v


XILINX_SRC_$(d)	= $(XILINX_SRC)/unisims/RAMB36.v \
	$(XILINX_SRC)/unisims/ARAMB36_INTERNAL.v \
	$(XILINX_SRC)/glbl.v

# Simulation
SIM 			      := $(call SRC_2_BIN, $(d)/aes_ctr_256_top.sim)
SRC_SIM_$(d)		:= $(XILINX_SRC_$(d)) $(SRC_$(d)) $(d)/rtl/sim_aes_ctr_256_top.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
