
# set the device part from command line argvs
set_part [lindex $argv 0]

# ----------------------------------------------------------------------------
# generate axi master vip - CONFIG INTERFACE
# ----------------------------------------------------------------------------
create_ip -name axi_vip \
          -vendor xilinx.com \
          -library ip \
          -version 1.1 \
          -module_name control_systolic_fpga_vip \
          -dir ./ip_generation
          
set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} \
                         CONFIG.PROTOCOL {AXI4LITE} \
                         CONFIG.SUPPORTS_NARROW {0} \
                         CONFIG.HAS_BURST {0} \
                         CONFIG.ADDR_WIDTH {12} \
                         CONFIG.HAS_LOCK {0} \
                         CONFIG.HAS_CACHE {0} \
                         CONFIG.HAS_REGION {0} \
                         CONFIG.HAS_QOS {0} \
                         CONFIG.HAS_PROT {0} \
                         CONFIG.HAS_WSTRB {1}] \
             [get_ips control_systolic_fpga_vip]
             
generate_target all [get_files  ./ip_generation/control_systolic_fpga_vip/control_systolic_fpga_vip.xci]



# ----------------------------------------------------------------------------
# generate axi slave vip - INPUT
# ----------------------------------------------------------------------------
create_ip -name axi_vip \
          -vendor xilinx.com \
          -library ip \
          -version 1.1 \
          -module_name slv_m01_parambuf_axi_vip \
          -dir ./ip_generation
          
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} \
                         CONFIG.PROTOCOL {AXI4} \
                         CONFIG.ADDR_WIDTH {64} \
                         CONFIG.DATA_WIDTH {512} \
                         CONFIG.SUPPORTS_NARROW {0} \
                         CONFIG.HAS_LOCK {0} \
                         CONFIG.HAS_CACHE {0} \
                         CONFIG.HAS_REGION {0} \
                         CONFIG.HAS_QOS {0} \
                         CONFIG.HAS_BRESP {0} \
                         CONFIG.HAS_BURST {0} \
                         CONFIG.HAS_RRESP {0} \
                         CONFIG.ID_WIDTH {0} \
                         CONFIG.HAS_ARESETN {1} \
                         CONFIG.HAS_PROT {0}] \
             [get_ips slv_m01_parambuf_axi_vip]
             
generate_target all [get_files  ./ip_generation/slv_m01_parambuf_axi_vip/slv_m01_parambuf_axi_vip.xci]

# ----------------------------------------------------------------------------
# generate axi slave vip - PARAMETERS
# ----------------------------------------------------------------------------
create_ip -name axi_vip \
          -vendor xilinx.com \
          -library ip \
          -version 1.1 \
          -module_name slv_m02_ibuf_axi_vip \
          -dir ./ip_generation
          
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} \
                         CONFIG.PROTOCOL {AXI4} \
                         CONFIG.ADDR_WIDTH {64} \
                         CONFIG.DATA_WIDTH {512} \
                         CONFIG.SUPPORTS_NARROW {0} \
                         CONFIG.HAS_LOCK {0} \
                         CONFIG.HAS_CACHE {0} \
                         CONFIG.HAS_REGION {0} \
                         CONFIG.HAS_QOS {0} \
                         CONFIG.HAS_BRESP {0} \
                         CONFIG.HAS_BURST {0} \
                         CONFIG.HAS_RRESP {0} \
                         CONFIG.ID_WIDTH {0} \
                         CONFIG.HAS_ARESETN {1} \
                         CONFIG.HAS_PROT {0}] \
             [get_ips slv_m02_ibuf_axi_vip]
             
generate_target all [get_files  ./ip_generation/slv_m02_ibuf_axi_vip/slv_m02_ibuf_axi_vip.xci]

# ----------------------------------------------------------------------------
# generate axi slave vip - OUTPUTS
# ----------------------------------------------------------------------------
create_ip -name axi_vip \
          -vendor xilinx.com \
          -library ip \
          -version 1.1 \
          -module_name slv_m03_obuf_axi_vip \
          -dir ./ip_generation
          
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} \
                         CONFIG.PROTOCOL {AXI4} \
                         CONFIG.ADDR_WIDTH {64} \
                         CONFIG.DATA_WIDTH {512} \
                         CONFIG.SUPPORTS_NARROW {0} \
                         CONFIG.HAS_LOCK {0} \
                         CONFIG.HAS_CACHE {0} \
                         CONFIG.HAS_REGION {0} \
                         CONFIG.HAS_QOS {0} \
                         CONFIG.HAS_BRESP {0} \
                         CONFIG.HAS_BURST {0} \
                         CONFIG.HAS_RRESP {0} \
                         CONFIG.ID_WIDTH {0} \
                         CONFIG.HAS_ARESETN {1} \
                         CONFIG.HAS_PROT {0}] \
             [get_ips slv_m03_obuf_axi_vip]
             
generate_target all [get_files  ./ip_generation/slv_m03_obuf_axi_vip/slv_m03_obuf_axi_vip.xci]

# ----------------------------------------------------------------------------
# generate axi slave vip - INSTRUCTIONS
# ----------------------------------------------------------------------------

create_ip -name axi_vip \
          -vendor xilinx.com \
          -library ip \
          -version 1.1 \
          -module_name slv_m00_imem_axi_vip \
          -dir ./ip_generation
          
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} \
                         CONFIG.PROTOCOL {AXI4} \
                         CONFIG.ADDR_WIDTH {64} \
                         CONFIG.DATA_WIDTH {512} \
                         CONFIG.SUPPORTS_NARROW {0} \
                         CONFIG.HAS_LOCK {0} \
                         CONFIG.HAS_CACHE {0} \
                         CONFIG.HAS_REGION {0} \
                         CONFIG.HAS_QOS {0} \
                         CONFIG.HAS_BRESP {0} \
                         CONFIG.HAS_BURST {0} \
                         CONFIG.HAS_RRESP {0} \
                         CONFIG.ID_WIDTH {0} \
                         CONFIG.HAS_ARESETN {1} \
                         CONFIG.HAS_PROT {0}] \
             [get_ips slv_m00_imem_axi_vip]
             
generate_target all [get_files  ./ip_generation/slv_m00_imem_axi_vip/slv_m00_imem_axi_vip.xci]