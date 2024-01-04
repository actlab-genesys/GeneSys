set top_module  SIMD_top
set libdir      "./path to DC compiler installation"

# path to db and sldb file
set list_lib "$libdir/NangateOpenCellLibrary.db \
$libdir/libraries/syn/dw_foundation.sldb"

# path to GeneSys RTL
set rtl_path "../../rtl"

set link_library $list_lib
set target_library $list_lib

# set symbol_library {}
# set wire_load_model ""
# set wire_load_mode enclosed
# set timing_use_enhanced_capacitance_modeling true

set search_path [concat $search_path $rtl_path]

# set synthetic_library {}
set link_path [concat  $link_library $synthetic_library]

# Start
remove_design -all
if {[file exists template]} {
	exec rm -rf template
}
exec mkdir template
if {![file exists gate]} {
	exec mkdir gateexit
}
if {![file exists rpt]} {
	exec mkdir rpt
}

# Compiler drectives
set compile_delete_unloaded_sequential_cells false
set design_lib WORK

define_design_lib $design_lib -path template

# read RTL
source ./read_rtl_genesys.tcl

analyze -format sverilog -lib $design_lib  $rtl_all

elaborate $top_module -lib $design_lib

current_design $top_module

# Link Design
set dc_shell_status [ link ]
if {$dc_shell_status == 0} {
	echo "****************************************************"
	echo "* ERROR!!!! Failed to Link...exiting prematurely.  *"
	echo "****************************************************"
	exit
}

# Default SDC Constraints
# read_sdc ./${top_module}.sdc

# Environment and compile options 
# set_max_area 0
set_leakage_optimization true

current_design $top_module

# add clock 350 mhz 10% input delay
# create_clock -name "clk" -period 2.86 -waveform { 1.43 2.86 }  { clk }
# set_input_delay 0.286 -clock clk [all_inputs]
# set_output_delay 0.286 -clock clk [all_outputs]

# # add clock 100 mhz 10% input  delay
# create_clock -name "clk" -period 10.000 -waveform { 5.000 10.000 }  { clk }
# set_input_delay 1 -clock clk [all_inputs]
# set_output_delay 1 -clock clk [all_outputs]

# # add clock 650 mhz 10% input  delay
create_clock -name "clk" -period 1.53 -waveform { 0.765 1.53 }  { clk }
set_input_delay 0.153 -clock clk [all_inputs]
set_output_delay 0.153 -clock clk [all_outputs]

# set dc_shell_status [ compile_ultra -no_autoungroup -exact_map ]

set dc_shell_status [ compile_ultra -no_autoungroup -exact_map ]

if {$dc_shell_status == 0} {
	echo "*******************************************************"
	echo "* ERROR!!!! Failed to compile...exiting prematurely.  *"
	echo "*******************************************************"
	exit
}
sh date

current_design $top_module
# define_name_rules verilog -remove_internal_net_bus -remove_port_bus
change_names -rules verilog -hierarchy

if {[info exists use_physopt] && ($use_physopt == 1)} {
	write -format verilog -hier -output [format "%s%s%s" gate/ $top_module _hier_fromdc.v]
} else {
	write -format verilog -hier -output [format "%s%s%s" gate/ $top_module .v]
}

current_design $top_module
write_sdc [format "%s%s%s" gate/ $top_module .sdc]

# Write Reports
redirect [format "%s%s%s" rpt/ $top_module _area.rep] { report_area -hierarchy }
redirect -append [format "%s%s%s" rpt/ $top_module _area.rep] { report_reference }
redirect [format "%s%s%s" rpt/ $top_module _cell.rep] { report_cell }
redirect [format "%s%s%s" rpt/ $top_module _design.rep] { report_design }
redirect [format "%s%s%s" rpt/ $top_module _power.rep] { report_power -hierarchy}
redirect [format "%s%s%s" rpt/ $top_module _timing.rep] \
  { report_timing -path full -max_paths 100 -nets -transition_time -capacitance -significant_digits 3}
redirect [format "%s%s%s" rpt/ $top_module _check_timing.rep] { check_timing }
redirect [format "%s%s%s" rpt/ $top_module _check_design.rep] { check_design }

write -f ddc -hier -o SIMD_top.ddc SIMD_top

# Check Design and Detect Unmapped Design
set unmapped_designs [get_designs -filter "is_unmapped == true" $top_module]
if {  [sizeof_collection $unmapped_designs] != 0 } {
	echo "****************************************************"
	echo "* ERROR!!!! Compile finished with unmapped logic.  *"
	echo "****************************************************"
	exit
}

echo "run.scr completed successfully"