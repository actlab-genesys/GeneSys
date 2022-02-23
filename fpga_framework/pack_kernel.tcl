##################################### Step 1: create vivado project and add design sources

# create ip project with part name in command line argvs
# Remove this if using the same project
create_project genesys_systolic_fpga ./genesys_systolic_fpga -part [lindex $argv 0]
set_property part xcu280-fsvh2892-2L-e [current_project]
set_property rtlkernel.dsa_name /opt/xilinx/platforms/xilinx_u280_xdma_201920_1/hw/xilinx_u280_xdma_201920_1.xsa [current_project]
set xpfm_path /opt/xilinx/platforms/xilinx_u280_xdma_201920_1/xilinx_u280_xdma_201920_1.xpfm
set kernel_wizard_dict [get_param rtl_kernel_wizard.features]
if {[expr [llength $kernel_wizard_dict] % 2]} {
set kernel_wizard_dict [dict create xpfm_path $xpfm_path]
} else {
dict set kernel_wizard_dict xpfm_path $xpfm_path
}
set_param rtl_kernel_wizard.features [dict get $kernel_wizard_dict]
set src_path [lindex $argv 1]
set cwd [lindex $argv 2]

# add design sources into project
#Using subst is not good practice, keep now for ease of use
add_files $src_path/include/config.vh
add_files [subst { $src_path/genesys_src/tag_sync.v \
   $src_path/genesys_src/pe.v \
   $src_path/genesys_src/compute_addr_gen.v \
   $src_path/genesys_src/signed_adder.v \
   $src_path/genesys_src/systolic_array.v \
   $src_path/genesys_src/base_addr_gen.v \
   $src_path/genesys_src/tag_logic.v \
   $src_path/genesys_src/mem_walker_stride_group.v \
   $src_path/genesys_src/weight_buffer.v \
   $src_path/genesys_src/bias_buffer.v \
   $src_path/genesys_src/instruction_memory.v \
   $src_path/genesys_src/ram_asymmetric.v \
   $src_path/genesys_src/parambuf_interface.v  
   $src_path/genesys_src/genesys_top_module.v \
   $src_path/genesys_src/obuf_interface.v \
   $src_path/genesys_src/decoder.v \
   $src_path/genesys_src/ram.v \
   $src_path/genesys_src/truncator.v \
   $src_path/genesys_src/controller_fsm_group.v \
   $src_path/genesys_src/fifo.v \
   $src_path/genesys_src/obuf.v \
   $src_path/genesys_src/obuf_wrapper.v \
   $src_path/genesys_src/ibuf_data_shuffler.v \
   $src_path/genesys_src/ibuf.v \
   $src_path/genesys_src/ibuf_interface.v \
   $src_path/genesys_src/instruction_memory_wrapper.v \
   $src_path/genesys_src/controller.sv \
   $src_path/genesys_src/register_sync.v \
   $src_path/genesys_src/macc.v \
   $src_path/genesys_src/mem_request_splitter.sv \
   $src_path/xilinx_macros/simple_dual_port_xpm.v \
   $src_path/xilinx_macros/asymmetric_fifo_xpm.v \
   $src_path/memory_interface/genesys_systolic_wrapper.sv \
   $src_path/memory_interface/control_m_axi_write_master_counter.sv \
   $src_path/memory_interface/control_m_axi_read_master.sv \
   $src_path/memory_interface/control_m_axi_write_master.sv \
   $src_path/memory_interface/systolic_fpga.v \
   $src_path/memory_interface/control_m_axi_read_master_fifo.sv \
   $src_path/memory_interface/control_m_axi_write_master_fifo.sv \
   $src_path/memory_interface/ddr_memory_interface_control_m_axi_fifo.sv \
   $src_path/memory_interface/ddr_memory_interface_control_m_axi.sv\
   $src_path/memory_interface/systolic_fpga_control_s_axi.v }]
   
   
   create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0

   set_property -dict [list CONFIG.C_PROBE19_WIDTH {32} CONFIG.C_PROBE18_WIDTH {32} \
   CONFIG.C_PROBE17_WIDTH {32} CONFIG.C_PROBE16_WIDTH {32} CONFIG.C_PROBE15_WIDTH {32} \
   CONFIG.C_PROBE14_WIDTH {32} CONFIG.C_PROBE13_WIDTH {32} CONFIG.C_PROBE12_WIDTH {32} \
   CONFIG.C_PROBE11_WIDTH {32} CONFIG.C_PROBE10_WIDTH {8} CONFIG.C_PROBE9_WIDTH {8} \
   CONFIG.C_PROBE8_WIDTH {8} CONFIG.C_PROBE7_WIDTH {8} CONFIG.C_PROBE6_WIDTH {8} \
   CONFIG.C_NUM_OF_PROBES {20} CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_ADV_TRIGGER {true} CONFIG.ALL_PROBE_SAME_MU {FALSE} CONFIG.C_PROBE0_MU_CNT {4} \
   CONFIG.C_PROBE1_MU_CNT {4} CONFIG.C_PROBE2_MU_CNT {4} CONFIG.C_PROBE3_MU_CNT {4} \
   CONFIG.C_PROBE4_MU_CNT {4} CONFIG.C_PROBE5_MU_CNT {4} CONFIG.C_PROBE6_MU_CNT {4} \
   CONFIG.C_PROBE7_MU_CNT {4} CONFIG.C_PROBE8_MU_CNT {4} CONFIG.C_PROBE9_MU_CNT {4} \
   CONFIG.C_PROBE10_MU_CNT {4} CONFIG.C_PROBE11_MU_CNT {4} CONFIG.C_PROBE12_MU_CNT {4} \
   CONFIG.C_PROBE13_MU_CNT {4} CONFIG.C_PROBE14_MU_CNT {4} CONFIG.C_PROBE15_MU_CNT {4} \
   CONFIG.C_PROBE16_MU_CNT {4} CONFIG.C_PROBE17_MU_CNT {4} CONFIG.C_PROBE18_MU_CNT {4} \
   CONFIG.C_PROBE19_MU_CNT {4}] [get_ips ila_0]

   generate_target all [get_files  ./../genesys-systolic/source/xilinx_macros/ila_0.xci]

   # removed files
   # $src_path/source/genesys_src/banked_scratchpad.v \
   # $src_path/source/genesys_src/scratchpad.v \
   # $src_path/source/genesys_src/obuf_data_shuffler.v \

update_compile_order -fileset sources_1

# create IP packaging project
#ipx::package_project -root_dir ./genesys_systolic_fpga_ip -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current true

source -notrace $cwd/package_kernel.tcl
# Packaging project
package_project ./genesys_systolic_fpga_ip xilinx.com kernel systolic_fpga
package_xo  -xo_path ../systolic_fpga.xo -kernel_name systolic_fpga -ip_directory $cwd/vivado_pack_krnl_project/genesys_systolic_fpga_ip -kernel_xml $cwd/kernel.xml

# Set required property for Vitis kernel
#set_property sdx_kernel true [ipx::current_core]
#set_property sdx_kernel_type rtl [ipx::current_core]

# Packaging Vivado IP
#ipx::update_source_project_archive -component [ipx::current_core]
#ipx::save_core [ipx::current_core]

# Generate Vitis Kernel from Vivado IP
#package_xo -force -xo_path ../systolic_fpga.xo -kernel_name genesys_systolic -ctrl_protocol ap_ctrl_hs -ip_directory ./genesys_systolic_fpga_ip -output_kernel_xml ../genesys_systolic.xml
