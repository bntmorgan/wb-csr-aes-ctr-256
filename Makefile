################################## COLORS ######################################

NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

################################## FUNCTIONS ###################################

define SRC_2_OBJ
  $(foreach src,$(1),$(patsubst sources/%,build/%,$(src)))
endef

define SRC_2_BIN
  $(foreach src,$(1),$(patsubst sources/%,binary/%,$(src)))
endef

define GEN_TARGETS
	$(1).bit $(1).routed.ncd $(1).ncd $(1).ngd $(1).ngc $(1).ucf $(1).prj $(1).xst
endef

define SIM_2_RUN
  $(foreach src,$(1),$(patsubst %.sim,%.run,$(src)))
endef

define RUN_2_SIM
  $(foreach src,$(1),$(patsubst %.run,./%.sim,$(src)))
endef

################################## STARTING RULE ###############################

all: targets simulations

################################## GLOBALS  ####################################

CORES_DIR := ./sources/cores
XILINX := /home/bmorgan/Xilinx/14.7/ISE_DS/ISE
XILINX_SRC := $(XILINX)/verilog/src

################################## INCLUDES ####################################

# Overriden in rules.mk
TARGETS :=
SIMS :=

dir	:= sources
include	$(dir)/rules.mk

################################## RULES #######################################

targets: $(TARGETS)

simulations: $(SIMS)

%.sim:
	@mkdir -p $(dir $@)
	@echo [VLG] $@ \> $@.out
	@iverilog -o $@ $^ \
		$(SIM_CFLAGS) -D__DUMP_FILE__=\"$(abspath $@).vcd\" &> $(abspath $@).out \
		-D__DIR__=\"$(realpath $(dir $@))\" \
		-DSIMULATION=1 \
	#	-y$(XILINX_SRC)/unisims $(XILINX_SRC)/glbl.v

%.isim: %.prj
	@mkdir -p $(dir $@)
	@echo [ISM] $@
	@cd $(dir $@) && vlogcomp -work work $(XILINX)/verilog/src/glbl.v
	@cd $(dir $@) && fuse -prj $(realpath $^) work.main work.glbl \
		-o $(abspath $@) -d __DUMP_FILE__=\"$(abspath $@).vcd\"  -d SIMULATION -L \
		unisims_ver -L secureip

%.load: %.bit
	@echo [LOD] $<
	@./impact.sh $(dir $<)impact.batch $(realpath $<) && cd $(dir $<) && impact \
		-batch impact.batch &> impact.batch.out

%.bit: %.routed.ncd %.ncd %.ngd %.ngc %.ucf %.prj %.xst
	@mkdir -p $(dir $@)
	@echo [BIT] $@ \> $@.out
	@cd $(dir $@) && bitgen -g LCK_cycle:6 -g Binary:Yes -g DriveDone:Yes \
		-w $(realpath $<) $(abspath $@) $(patsubst %.bit, %.pcf, $(abspath $@)) \
		&> $(abspath $@).out

%.routed.ncd: %.ncd 
	@mkdir -p $(dir $@)
	@echo [RTE] $@ \> $@.out
	@cd $(dir $@) && par -mt 4 -ol high -w $(realpath $^) $(abspath $@) &> \
		$(abspath $@).out

%.ncd: %.ngd
	@mkdir -p $(dir $@)
	@echo [NCD] $@ \> $@.out
	@cd $(dir $@) && map -mt 4 -ol high -t 20 -w $(realpath $^) &> $(abspath \
		$@).out

%.ngd: %.ucf %.ngc
	@mkdir -p $(dir $@)
	@echo [NGD] $@ \> $@.out
	@cd $(dir $@) && ngdbuild -uc $(realpath $^) &> $(abspath $@).out

%.ngc: %.xst %.prj
	@mkdir -p $(dir $@)
	@echo [NGC] $@ \> $@.out
	@cd $(dir $@) && xst -ifn $(abspath $<) &> $(abspath $@).out

%.prj:
	@mkdir -p $(dir $@)
	@echo [PRJ] $@
	@rm -f $@
	@for i in `echo $^`; do \
		echo "verilog work `pwd`/$$i" >> $@; \
	done

%.xst:
	@mkdir -p $(dir $@)
	@echo [XST] $@
	@cp $^ $@

%.ucf:
	@mkdir -p $(dir $@)
	@echo [UCF] $@
	@cat $^ > $@

load: binary/remote/system.bit
	@echo [LOD] $<
	@./impact.sh $(dir $<)impact.batch $(realpath $<) && cd $(dir $<) && impact \
		-batch impact.batch > impact.batch.out

run_simulations: $(call SIM_2_RUN, $(SIMS)) 

%.run: %.sim
	@echo [RUN] $< ">" $<.run
	@cd $(dir $@) && $(realpath $<) > $(realpath $<).run

info:
	@echo TARGETS [$(TARGETS)]
	@echo SIMS [$(SIMS)]

clean:
	@echo [CLR] $(dir $(TARGETS))
	@echo [CLR] $(SIMS)
	@rm -fr $(dir $(TARGETS)) $(SIMS)

mr-proper: mr-proper-vim

mr-proper-vim:
	@echo [CLR] *.swp
	@find . | grep .swp | xargs rm -f
