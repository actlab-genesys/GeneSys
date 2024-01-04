# This is a generated file. Use and modify at your own risk.
################################################################################

set kernel_name    "systolic_fpga"
set kernel_vendor  "mycompany.com"
set kernel_library "kernel"

##############################################################################

proc edit_core {core} {
  set bif      [::ipx::get_bus_interfaces -of $core  "m00_imem_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  set bif      [::ipx::get_bus_interfaces -of $core  "m01_parambuf_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  set bif      [::ipx::get_bus_interfaces -of $core  "m02_ibuf_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  set bif      [::ipx::get_bus_interfaces -of $core  "m03_obuf_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  set bif      [::ipx::get_bus_interfaces -of $core  "m04_simd_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  

  ::ipx::associate_bus_interfaces -busif "m00_imem_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "m01_parambuf_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "m02_ibuf_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "m03_obuf_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "m04_simd_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "s_axi_control" -clock "ap_clk" $core

  # Specify the freq_hz parameter 
  set clkbif      [::ipx::get_bus_interfaces -of $core "ap_clk"]
  set clkbifparam [::ipx::add_bus_parameter -quiet "FREQ_HZ" $clkbif]
  # Set desired frequency                   
  set_property value 250000000 $clkbifparam
  # set value_resolve_type 'user' if the frequency can vary. 
  set_property value_resolve_type user $clkbifparam
  # set value_resolve_type 'immediate' if the frequency cannot change. 
  # set_property value_resolve_type immediate $clkbifparam
  set mem_map    [::ipx::add_memory_map -quiet "s_axi_control" $core]
  set addr_block [::ipx::add_address_block -quiet "reg0" $mem_map]

  set reg      [::ipx::add_register "CTRL" $addr_block]
  set_property description    "Control signals"    $reg
  set_property address_offset 0x000 $reg
  set_property size           32    $reg
  set field [ipx::add_field AP_START $reg]
    set_property ACCESS {read-write} $field
    set_property BIT_OFFSET {0} $field
    set_property BIT_WIDTH {1} $field
    set_property DESCRIPTION {Control signal Register for 'ap_start'.} $field
    set_property MODIFIED_WRITE_VALUE {modify} $field
  set field [ipx::add_field AP_DONE $reg]
    set_property ACCESS {read-only} $field
    set_property BIT_OFFSET {1} $field
    set_property BIT_WIDTH {1} $field
    set_property DESCRIPTION {Control signal Register for 'ap_done'.} $field
    set_property READ_ACTION {modify} $field
  set field [ipx::add_field AP_IDLE $reg]
    set_property ACCESS {read-only} $field
    set_property BIT_OFFSET {2} $field
    set_property BIT_WIDTH {1} $field
    set_property DESCRIPTION {Control signal Register for 'ap_idle'.} $field
    set_property READ_ACTION {modify} $field
  set field [ipx::add_field AP_READY $reg]
    set_property ACCESS {read-only} $field
    set_property BIT_OFFSET {3} $field
    set_property BIT_WIDTH {1} $field
    set_property DESCRIPTION {Control signal Register for 'ap_ready'.} $field
    set_property READ_ACTION {modify} $field
  set field [ipx::add_field RESERVED_1 $reg]
    set_property ACCESS {read-only} $field
    set_property BIT_OFFSET {4} $field
    set_property BIT_WIDTH {3} $field
    set_property DESCRIPTION {Reserved.  0s on read.} $field
    set_property READ_ACTION {modify} $field
  set field [ipx::add_field AUTO_RESTART $reg]
    set_property ACCESS {read-write} $field
    set_property BIT_OFFSET {7} $field
    set_property BIT_WIDTH {1} $field
    set_property DESCRIPTION {Control signal Register for 'auto_restart'.} $field
    set_property MODIFIED_WRITE_VALUE {modify} $field
  set field [ipx::add_field RESERVED_2 $reg]
    set_property ACCESS {read-only} $field
    set_property BIT_OFFSET {8} $field
    set_property BIT_WIDTH {24} $field
    set_property DESCRIPTION {Reserved.  0s on read.} $field
    set_property READ_ACTION {modify} $field

  set reg      [::ipx::add_register "GIER" $addr_block]
  set_property description    "Global Interrupt Enable Register"    $reg
  set_property address_offset 0x004 $reg
  set_property size           32    $reg

  set reg      [::ipx::add_register "IP_IER" $addr_block]
  set_property description    "IP Interrupt Enable Register"    $reg
  set_property address_offset 0x008 $reg
  set_property size           32    $reg

  set reg      [::ipx::add_register "IP_ISR" $addr_block]
  set_property description    "IP Interrupt Status Register"    $reg
  set_property address_offset 0x00C $reg
  set_property size           32    $reg

  set reg      [::ipx::add_register -quiet "slv_reg0_out" $addr_block]
  set_property address_offset 0x010 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg1_out" $addr_block]
  set_property address_offset 0x018 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg2_out" $addr_block]
  set_property address_offset 0x020 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg3_out" $addr_block]
  set_property address_offset 0x028 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg4_out" $addr_block]
  set_property address_offset 0x030 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg5_out" $addr_block]
  set_property address_offset 0x038 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg6_out" $addr_block]
  set_property address_offset 0x040 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg7_out" $addr_block]
  set_property address_offset 0x048 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg8_out" $addr_block]
  set_property address_offset 0x050 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg9_out" $addr_block]
  set_property address_offset 0x058 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg10_out" $addr_block]
  set_property address_offset 0x060 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg11_out" $addr_block]
  set_property address_offset 0x068 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg12_out" $addr_block]
  set_property address_offset 0x070 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg13_out" $addr_block]
  set_property address_offset 0x078 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "slv_reg14_out" $addr_block]
  set_property address_offset 0x080 $reg
  set_property size           [expr {4*8}]   $reg

  set reg      [::ipx::add_register -quiet "axi00_imem_ptr0" $addr_block]
  set_property address_offset 0x088 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg] 
  set_property value m00_imem_axi $regparam 

  set reg      [::ipx::add_register -quiet "axi01_parambuf_ptr0" $addr_block]
  set_property address_offset 0x094 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg] 
  set_property value m01_parambuf_axi $regparam 

  set reg      [::ipx::add_register -quiet "axi02_ibuf_ptr0" $addr_block]
  set_property address_offset 0x0a0 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg] 
  set_property value m02_ibuf_axi $regparam 

  set reg      [::ipx::add_register -quiet "axi03_obuf_ptr0" $addr_block]
  set_property address_offset 0x0ac $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg] 
  set_property value m03_obuf_axi $regparam

  set reg      [::ipx::add_register -quiet "axi04_simd_ptr0" $addr_block]
  set_property address_offset 0x0b8 $reg
  set_property size           [expr {8*8}]   $reg
  set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg] 
  set_property value m04_simd_axi $regparam 

  set_property slave_memory_map_ref "s_axi_control" [::ipx::get_bus_interfaces -of $core "s_axi_control"]

  set_property xpm_libraries {XPM_CDC XPM_MEMORY XPM_FIFO} $core
  set_property sdx_kernel true $core
  set_property sdx_kernel_type rtl $core
}
##############################################################################

proc package_project {path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [ipx::package_project -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -taxonomy "/KernelIP" -import_files -set_current false ]
  foreach user_parameter [list C_S_AXI_CONTROL_ADDR_WIDTH C_S_AXI_CONTROL_DATA_WIDTH C_M00_IMEM_AXI_ADDR_WIDTH C_M00_IMEM_AXI_DATA_WIDTH C_M01_PARAMBUF_AXI_ADDR_WIDTH C_M01_PARAMBUF_AXI_DATA_WIDTH C_M02_IBUF_AXI_ADDR_WIDTH C_M02_IBUF_AXI_DATA_WIDTH C_M03_OBUF_AXI_ADDR_WIDTH C_M03_OBUF_AXI_DATA_WIDTH] {
    ipx::remove_user_parameter $user_parameter $core
  }
  ipx::create_xgui_files $core
  #set_property supported_families { } $core
  #set_property auto_family_support_level level_2 $core
  #set_property used_in {out_of_context implementation synthesis} [ipx::get_files -type xdc -of_objects [ipx::get_file_groups "xilinx_anylanguagesynthesis" -of_objects $core] *_ooc.xdc]
  edit_core $core
  ipx::update_checksums $core
  ipx::check_integrity -kernel $core
  ipx::check_integrity -xrt $core
  ipx::save_core $core
  ipx::unload_core $core
  unset core
}

##############################################################################

proc package_project_dcp {path_to_dcp path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [ipx::package_checkpoint -dcp_file $path_to_dcp -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -name $kernel_name -taxonomy "/KernelIP" -force]
  edit_core $core
  ipx::update_checksums $core
  ipx::check_integrity -kernel $core
  ipx::check_integrity -xrt $core
  ipx::save_core $core
  ipx::unload_core $core
  unset core
}

##############################################################################

proc package_project_dcp_and_xdc {path_to_dcp path_to_xdc path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [ipx::package_checkpoint -dcp_file $path_to_dcp -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -name $kernel_name -taxonomy "/KernelIP" -force]
  edit_core $core
  set rel_path_to_xdc [file join "impl" [file tail $path_to_xdc]]
  set abs_path_to_xdc [file join $path_to_packaged $rel_path_to_xdc]
  file mkdir [file dirname $abs_path_to_xdc]
  file copy $path_to_xdc $abs_path_to_xdc
  set xdcfile [ipx::add_file $rel_path_to_xdc [ipx::add_file_group "xilinx_implementation" $core]]
  set_property type "xdc" $xdcfile
  set_property used_in [list "implementation"] $xdcfile
  ipx::update_checksums $core
  ipx::check_integrity -kernel $core
  ipx::check_integrity -xrt $core
  ipx::save_core $core
  ipx::unload_core $core
  unset core
}

##############################################################################
