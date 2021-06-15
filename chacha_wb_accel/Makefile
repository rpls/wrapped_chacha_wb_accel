PDK_ROOT ?= /opt/pdks

TOPLEVEL_LANG = verilog
TOPLEVEL ?= chacha_wb_accel
VERILOG_SOURCES = $(TOPLEVEL)$(if $(LVS),_lvs).v
MODULE = test_$(TOPLEVEL)
PLUSARGS += -fst
COMPILE_ARGS += -I $(PDK_ROOT)/sky130A

include $(shell cocotb-config --makefiles)/Makefile.sim

$(TOPLEVEL)_lvs.v: $(TOPLEVEL).lvs.powered.v
	echo "\`define UNIT_DELAY #1" > $@
	echo "\`define FUNCTIONAL" >> $@
	echo "\`define USE_POWER_PINS" >> $@
	echo "\`include \"libs.ref/sky130_fd_sc_hd/verilog/primitives.v\"" >> $@
	echo "\`include \"libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v\"" >> $@
	cat $< >> $@

WRAPPER_DIR=

deploy: $(TOPLEVEL).v test_$(TOPLEVEL).py Makefile
	@if [ -z "$(WRAPPER_DIR)" -o \! -d "$(WRAPPER_DIR)" ]; then \
		echo "You must define WRAPPER_DIR! make WRAPPER_DIR=../etc deploy"; \
		exit 1; \
	fi
	install -m644 -t $(WRAPPER_DIR) $^
	sed -i -e "s/chacha_wb_accel/$(TOPLEVEL)/" $(WRAPPER_DIR)/Makefile

all: check

.PHONY: check
check: sim
	test -f results.xml
	! grep failure results.xml
