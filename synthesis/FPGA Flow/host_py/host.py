from genesys_driver import GenesysDriver

test_name= 'layer0_gemm1'
data_info_file = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/examples/micro23_demo/hw-verification-demo/16x16/sac_model_simd_repo_operand_storage_info.json'
base_path = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/examples/micro23_demo/hw-verification-demo/16x16/'
genesys_binary = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/fpga_framework/binaries/systolic_fpga_16.hw_emu.xclbin'
relative_path=1

driver = GenesysDriver(test_name=test_name,data_info_file=data_info_file,base_path=base_path,genesys_binary=genesys_binary,relative_path=relative_path)
driver.initialize()
driver.run()
driver.check_output()

