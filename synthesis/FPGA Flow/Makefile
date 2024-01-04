

ECHO=@echo

.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make gen_ip"
	$(ECHO) "      Command to generate the IPs used in this design"
	$(ECHO) ""
	$(ECHO) "  make pack_kernel"
	$(ECHO) "      Command to pack the module krnl_cbc to Vitis kernel"
	$(ECHO) ""
	$(ECHO) "  make runsim"
	$(ECHO) "      Command to run the simulation"
	$(ECHO) ""
	$(ECHO) "  make build_hw"
	$(ECHO) "      Command to build xclbin files for Alveo platform, including krnl_cbc and krnl_aes kernels"
	$(ECHO) ""
	$(ECHO) "  make build_sw"
	$(ECHO) "      Command to build host software for xclbin test"
	$(ECHO) ""
	$(ECHO) "  make clean"
	$(ECHO) "      Command to remove all the generated files."

CWD := $(shell pwd)

# Edit path here to change design sources directory or set variable in shell and use make -e, latter is not recommended
SRC_PATH := $(CWD)/../rtl

#PART setting: uncomment the line matching your Alveo card
#PART := xcu200-fsgd2104-2-e
#PART := cu250-figd2104-2L-e
#PART := xcu50-fsvh2104-2-e
PART := xcvup9p-flgb2104-2-i

# PLATFORM setting: uncomment the lin matching your Alveo card
PLATFORM := xilinx_aws-vu9p-f1_shell-v04261818_201920_3

# TARGET: set the build target, can be hw or hw_emu
TARGET := hw_emu

.phony: clean traces


################## emconfigutil generates an emulation configuration file which defines the device type and quantity of devices to emulate for the specified platform
emconfig:
	emconfigutil --platform xilinx_u280_xdma_201920_1 --nd 1

################## resource generation and simulation 
gen_ip:
	rm -rf ip_generation; mkdir ip_generation; vivado -mode batch -source ./gen_ip.tcl -tclargs $(PART)


pack_kernel:
	rm -rf vivado_pack_krnl_project; mkdir vivado_pack_krnl_project; cd vivado_pack_krnl_project; vivado -mode batch -source $(CWD)/pack_kernel.tcl -tclargs $(PART) $(SRC_PATH) $(CWD)

runsim:
	./runsim_xsim.sh


################## hardware build 
NCPUS := $(shell grep -c ^processor /proc/cpuinfo)
#JOBS := $(shell expr $(NCPUS) - 30)
JOBS := 6

XOCCFLAGS := --platform $(PLATFORM) -t $(TARGET)  -s -g
#XOCCLFLAGS := --link --optimize 3 --vivado.synth.jobs $(JOBS) --vivado.impl.jobs $(JOBS)
XOCCLFLAGS := --link --optimize quick --vivado.synth.jobs $(JOBS) --vivado.impl.jobs $(JOBS)
# You could uncomment following line and modify the options for hardware debug/profiling
DEBUG_OPT := --debug.chipscope systolic_fpga_1 --debug.protocol all --profile_kernel data:all:all:all:all
#DEBUG_OPT := --debug.protocol all
#PROFILE := --profile_kernel data:all:all:all:all

#Default Steps :
#system_link, vpl, vpl.create_project, vpl.create_bd, vpl.update_bd, 
#vpl.generate_target, vpl.config_hw_runs, vpl.synth, vpl.impl, vpl.impl.opt_design, 
#vpl.impl.place_design, vpl.impl.route_design, vpl.impl.write_bitstream, 
#rtdgen, xclbinutil, xclbinutilinfo, generate_sc_driver

INCREMENTAL_BUILD := vpl.synth

build_hw:
	v++ $(XOCCLFLAGS) $(XOCCFLAGS)  --config systolic_fpga.cfg --kernel_frequency 0:10 -o systolic_fpga.$(TARGET).xclbin systolic_fpga.xo

################## software build for XRT Native API code
CXXFLAGS := -std=c++1y -Wno-deprecated-declarations -D$(TEST_NAME)
CXXFLAGS += -I$(XILINX_XRT)/include
LDFLAGS := -L$(XILINX_XRT)/lib
LDFLAGS += $(LDFLAGS) -lpthread
#EXECUTABLE := genesys_driver
EXECUTABLE := $(TARGET_DIR)/$(TEST_NAME)

HOST_SRCS := ./host/genesys_driver.cpp
HOST_INCLUDES := -I./host/
build_sw: $(EXECUTABLE)

$(EXECUTABLE): $(HOST_SRCS)
	$(CXX) -o $(EXECUTABLE) $^ $(CXXFLAGS) $(LDFLAGS) $(HOST_INCLUDES) -lOpenCL -ljsoncpp


UTILITY_EXEC := openCL_version_checker
UTILITY_SRCS := ./host/openCL_version.cpp

build_openCL_version_checker: openCL_version_checker

$(UTILITY_EXEC): $(UTILITY_SRCS)
	$(CXX) -o $(UTILITY_EXEC) $^ -lOpenCL


################## clean up
clean:
	$(RM) -rf ip_generation vivado_pack_krnl_project
	$(RM) -rf *.xo *.xclbin *.xclbin.info *.xclbin.link_summary *.jou *.log *.xo.compile_summary _x
	$(RM) -rf *.dat *.pb xsim.dir *.ltx *.csv *.json *.protoinst *.wdb *.wcfg genesys_driver
