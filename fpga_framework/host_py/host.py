from genesys_driver import GenesysDriver

test_name= 'layer0_gemm_relu1'
data_info_file = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/examples/micro23_demo/hw-verification-demo/sac_model_simd_repo_genesys4x4/program/sac_model_simd_repo_operand_storage_info.json'
base_path = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/examples/micro23_demo/hw-verification-demo/sac_model_simd_repo_genesys4x4'
genesys_binary = '/home/centos/aws-fpga/hdk/cl/developer_designs/GeneSys/fpga_framework/systolic_fpga.hw_emu.xclbin'

driver = GenesysDriver(test_name=test_name,data_info_file=data_info_file,base_path=base_path,genesys_binary=genesys_binary )
driver.initialize()
driver.run()
driver.check_output()
driver.get_performance_data()
driver.plot_pc_data()


