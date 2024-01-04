import os
from subprocess import call

directory = os.getcwd()
test_list = []
target_dir = ''
log_dir = 'emu_logs'
csv_file='metrics.csv'
platform = 'xilinx_u280_xdma_201920_1'

SA_2x2_reg_list = ["resnet50_1_conv_case1"]
SA_4x4_reg_list = ["resnet50_1_conv_case1"]
SA_8x8_reg_list = ["RESNET50_CUSTOM_CONV_8X8_T4_12","RESNET50_CUSTOM_CONV_8X8_T4_7","RESNET50_CUSTOM_CONV_8X8_T4_15","RESNET50_CUSTOM_CONV_8X8_T4_17","RESNET50_CUSTOM_CONV_8X8_T4_3","RESNET50_CUSTOM_CONV_8X8_T4_5","RESNET50_CUSTOM_CONV_8X8_T4_20","RESNET50_CUSTOM_CONV_8X8_T4_18","RESNET50_CUSTOM_CONV_8X8_T4_10","RESNET50_CUSTOM_CONV_8X8_T4_4","RESNET50_CUSTOM_CONV_8X8_T4_16","RESNET50_CUSTOM_CONV_8X8_T4_19","RESNET50_CUSTOM_CONV_8X8_T4_9","RESNET50_CUSTOM_CONV_8X8_T4_6","RESNET50_CUSTOM_CONV_8X8_T4_2","RESNET50_CUSTOM_CONV_8X8_T4_0","RESNET50_CUSTOM_CONV_8X8_T4_21","RESNET50_CUSTOM_CONV_8X8_T4_8","RESNET50_CUSTOM_CONV_8X8_T4_1","RESNET50_CUSTOM_CONV_8X8_T4_14","RESNET50_CUSTOM_CONV_8X8_T4_11","RESNET50_CUSTOM_CONV_8X8_T4_13","FPGA_8X8_TILE3_CASE4_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE1_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE7_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE7_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE0_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE0_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE5_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE7_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE6_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE8_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE2_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE5_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE9_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE9_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE1_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE0_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE5_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE3_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE3_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE9_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE2_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE2_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE1_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE6_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE6_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE3_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE8_IC_OH_OW_CONV","FPGA_8X8_TILE3_CASE4_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE4_IC_OC_OH_OW_CONV","FPGA_8X8_TILE3_CASE8_OC_OH_OW_CONV","RESNET50_CUSTOM_CONV_8X8_T2_9","RESNET50_CUSTOM_CONV_8X8_T2_19","RESNET50_CUSTOM_CONV_8X8_T2_0","RESNET50_CUSTOM_CONV_8X8_T2_13","RESNET50_CUSTOM_CONV_8X8_T2_5","RESNET50_CUSTOM_CONV_8X8_T2_12","RESNET50_CUSTOM_CONV_8X8_T2_6","RESNET50_CUSTOM_CONV_8X8_T2_1","RESNET50_CUSTOM_CONV_8X8_T2_17","RESNET50_CUSTOM_CONV_8X8_T2_2","RESNET50_CUSTOM_CONV_8X8_T2_20","RESNET50_CUSTOM_CONV_8X8_T2_7","RESNET50_CUSTOM_CONV_8X8_T2_15","RESNET50_CUSTOM_CONV_8X8_T2_14","RESNET50_CUSTOM_CONV_8X8_T2_16","RESNET50_CUSTOM_CONV_8X8_T2_10","RESNET50_CUSTOM_CONV_8X8_T2_4","RESNET50_CUSTOM_CONV_8X8_T2_11","RESNET50_CUSTOM_CONV_8X8_T2_3","RESNET50_CUSTOM_CONV_8X8_T2_21","RESNET50_CUSTOM_CONV_8X8_T2_18","RESNET50_CUSTOM_CONV_8X8_T2_8"]

SA_16x16_reg_list = ["resnet50_custom_conv_16x16_t9_0" , "resnet50_custom_conv_16x16_t9_1" , "resnet50_custom_conv_16x16_t9_2" , "resnet50_custom_conv_16x16_t9_3" , 
                     "resnet50_custom_conv_16x16_t9_4" , "resnet50_custom_conv_16x16_t9_5" , "resnet50_custom_conv_16x16_t9_6" , "resnet50_custom_conv_16x16_t9_7" , 
                     "resnet50_custom_conv_16x16_t9_8" , "resnet50_custom_conv_16x16_t9_9" , "resnet50_custom_conv_16x16_t9_10", "resnet50_custom_conv_16x16_t9_11", 
                     "resnet50_custom_conv_16x16_t9_12", "resnet50_custom_conv_16x16_t9_13", "resnet50_custom_conv_16x16_t9_14", "resnet50_custom_conv_16x16_t9_15", 
                     "resnet50_custom_conv_16x16_t9_16", "resnet50_custom_conv_16x16_t9_17", "resnet50_custom_conv_16x16_t9_18", "resnet50_custom_conv_16x16_t9_19", 
                     "resnet50_custom_conv_16x16_t9_20", "resnet50_custom_conv_16x16_t9_21" ]

SA_32x32_reg_list = ["resnet50_1_conv_case1"]
SA_64x64_reg_list = ["resnet50_1_conv_case1" ,"resnet50_1_conv_case101" ,"resnet50_1_conv_case102", "resnet50_1_conv_case103", "resnet50_1_conv_case104", "resnet50_1_conv_case105" 
                    "resnet50_1_conv_case106", "resnet50_1_conv_case107", "resnet50_1_conv_case108", "resnet50_1_conv_case109", "resnet50_1_conv_case11", "resnet50_1_conv_case110" 
                    "resnet50_1_conv_case111", "resnet50_1_conv_case113",  "resnet50_1_conv_case114", "resnet50_1_conv_case115", "resnet50_1_conv_case116", "resnet50_1_conv_case117" 
                    "resnet50_1_conv_case118", "resnet50_1_conv_case119", "resnet50_1_conv_case120", "resnet50_1_conv_case121", "resnet50_1_conv_case123", "resnet50_1_conv_case124" 
                    "resnet50_1_conv_case126", "resnet50_1_conv_case127", "resnet50_1_conv_case128", "resnet50_1_conv_case129", "resnet50_1_conv_case13", "resnet50_1_conv_case130"
                    "resnet50_1_conv_case131", "resnet50_1_conv_case132", "resnet50_1_conv_case133", "resnet50_1_conv_case134", "resnet50_1_conv_case136", "resnet50_1_conv_case15" 
                    "resnet50_1_conv_case17" ,"resnet50_1_conv_case18", "resnet50_1_conv_case19", "resnet50_1_conv_case21", "resnet50_1_conv_case22", "resnet50_1_conv_case24"
                    "resnet50_1_conv_case25" ,"resnet50_1_conv_case26", "resnet50_1_conv_case27", "resnet50_1_conv_case29", "resnet50_1_conv_case3", "resnet50_1_conv_case30" 
                    "resnet50_1_conv_case31" ,"resnet50_1_conv_case32", "resnet50_1_conv_case36", "resnet50_1_conv_case37", "resnet50_1_conv_case38", "resnet50_1_conv_case39"
                    "resnet50_1_conv_case42" ,"resnet50_1_conv_case43", "resnet50_1_conv_case44", "resnet50_1_conv_case45", "resnet50_1_conv_case46", "resnet50_1_conv_case47"
                    "resnet50_1_conv_case48" ,"resnet50_1_conv_case49", "resnet50_1_conv_case5", "resnet50_1_conv_case50", "resnet50_1_conv_case51", "resnet50_1_conv_case52"
                    "resnet50_1_conv_case53" ,"resnet50_1_conv_case54", "resnet50_1_conv_case55", "resnet50_1_conv_case56", "resnet50_1_conv_case57", "resnet50_1_conv_case58"
                    "resnet50_1_conv_case59" ,"resnet50_1_conv_case60", "resnet50_1_conv_case61", "resnet50_1_conv_case62", "resnet50_1_conv_case63", "resnet50_1_conv_case64"
                    "resnet50_1_conv_case66" ,"resnet50_1_conv_case67", "resnet50_1_conv_case69", "resnet50_1_conv_case7", "resnet50_1_conv_case70", "resnet50_1_conv_case71"
                    "resnet50_1_conv_case72" ,"resnet50_1_conv_case73", "resnet50_1_conv_case74", "resnet50_1_conv_case75", "resnet50_1_conv_case76", "resnet50_1_conv_case78"
                    "resnet50_1_conv_case82" ,"resnet50_1_conv_case85", "resnet50_1_conv_case88", "resnet50_1_conv_case9", "resnet50_1_conv_case90", "resnet50_1_conv_case94"
                    "resnet50_1_conv_case95" ,"resnet50_1_conv_case96", "resnet50_1_conv_case97", "resnet50_1_conv_case98", "resnet50_1_conv_case99"]

def print_menu():
    print (30 * "-" , "ENTER NUMBER TO CHOOSE SYSTOLIC ARRAY SIZE" , 30 * "-")
    print ("1. Systolic Array 2x2")
    print ("2. Systolic Array 4x4")
    print ("3. Systolic Array 8x8")
    print ("4. Systolic Array 16x16")
    print ("5. Systolic Array 32x32")
    print ("6. Systolic Array 64x64")
    print ("7. Exit")
    print (67 * "-")

    choice = input("Enter your choice [1-7]: ")
    
    print ("\n")
    print (30 * "-" , "ENTER NUMBER TO CHOOSE REQUIRED FUNCTION" , 30 * "-")
    print ("1. Compile Regression Tests")
    print ("2. Run Regression Tests")
    print ("3. Compile + Run Regression Tests")
    
    function_choice = input("Enter your choice [1-3]: ")

    loop=True      
    while loop:         
        loop=False
        global target_dir
        if choice=='1': 
            print ("Compiling Regression Tests for Systolic Array 2x2")
            test_list_selection(choice)  
            target_dir = "bin_SA_2x2"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
            clean()
            os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
                compile_regression_list()
                run_regression()  
                generate_csv()
        elif choice=='2':  
            print ("Compiling Regression Tests for Systolic Array 4x4")    
            test_list_selection(choice)   
            target_dir = "bin_SA_4x4"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
            clean()
            os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
                compile_regression_list()
                run_regression()
                generate_csv()
        elif choice=='3':  
            print ("Compiling Regression Tests for Systolic Array 8x8")  
            test_list_selection(choice)   
            target_dir = "bin_SA_8x8"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
           # clean()
           # os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
            #    compile_regression_list()
            #    run_regression()
                generate_csv()
        elif choice=='4': 
            print ("Compiling Regression Tests for Systolic Array 16x16")   
            test_list_selection(choice)   
            target_dir = "bin_SA_16x16"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
            clean()
            os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
                compile_regression_list()
                run_regression()
                generate_csv()
        elif choice=='5':  
            print ("Compiling Regression Tests for Systolic Array 32x32")    
            test_list_selection(choice)  
            target_dir = "bin_SA_32x32"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
            clean()
            os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
                compile_regression_list()
                run_regression()
                generate_csv()
        elif choice=='6':    
            print ("Compiling Regression Tests for Systolic Array 64x64")    
            test_list_selection(choice)    
            target_dir = "bin_SA_64x64"
            target_path = directory + "/" + target_dir
            print ("Creating executable at ")
            print (target_path)
            clean()
            os.mkdir(target_path)
            if function_choice == '1':
                compile_regression_list()
            elif function_choice == '2': 
                run_regression()
                generate_csv()
            else:
                compile_regression_list()
                run_regression()
                generate_csv()
        else:
            # Any integer inputs other than values 1-5 we print an error message
            print("Wrong option selection. Exiting")

def test_list_selection(sa_dim):
    global test_list
    global SA_2x2_reg_list
    global SA_4x4_reg_list
    global SA_8x8_reg_list
    global SA_16x16_reg_list
    global SA_32x32_reg_list
    global SA_64x64_reg_list
    
    if sa_dim == '1':
        test_list = SA_2x2_reg_list
    elif sa_dim == '2':
        test_list = SA_4x4_reg_list
    elif sa_dim == '3':
        test_list = SA_8x8_reg_list
    elif sa_dim == '4':
        test_list = SA_16x16_reg_list
    elif sa_dim == '5':
        test_list = SA_32x32_reg_list
    else:
        test_list = SA_64x64_reg_list
    

def compile_regression_list():
    global test_list
    print ("test_list is ")
    print (test_list)
    for test_name in test_list:
        cmd = 'make build_sw TARGET_DIR=' + target_dir + ' TEST_NAME=' + test_name
        print (cmd)
        os.system(cmd)

def run_regression():
    log_fn = "_log.txt"
 #   setup_cmd = 'export XCL_EMULATION_MODE=hw_emu'
 #   os.environ['XCL_EMULATION_MODE'] = 'hw_emu'
 #   print(setup_cmd)
 #   em_config_cmd = 'emconfigutil --platform '+platform
 #   os.system(em_config_cmd)
 #   em_cp_cmd = 'cp emconfig.json '+target_dir+'/'
 #   os.system(em_cp_cmd)
    os.mkdir(log_dir)
 #   print(em_config_cmd)
    for i in range(len(test_list)):
        reprog_cmd = './vadd krnl_vadd.xclbin'
        os.system(reprog_cmd)
        cmd = target_dir+'/'+test_list[i]+' > '+log_dir+'/'+test_list[i]+log_fn
        os.system(cmd)


def generate_csv():
    file_out = open(log_dir+"/"+csv_file,"a")
    file_out.write("TESTCASE,INPUT_TRANSFER_TIME (sec),INPUT_TRANSFER_CYCLES,EXECUTION_TIME (sec),EXECUTION_CYCLES,OUTPUT_TRANSFER_TIME (sec),OUTPUT_TRANSFER_CYCLES,RESULT\n")
    for root, dirs, files in os.walk(log_dir):
        for filename in files:
            if ((".txt" in filename) and ~("swp" in filename)):
                print(root+"/"+filename)
                logfl = open(root+"/"+filename,"r")
                entry = ""
                entry = entry+filename

                for line in logfl:
                    if ("TEST PASSED" in line):
                        entry = entry+",TEST PASSED"
                    elif ("TEST FAILED" in line):
                        entry = entry+",TEST FAILED"
                    elif ("Input Transfer Time" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                    elif ("Input Transfer Cycles" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                    elif ("Execution Time" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                    elif ("Execution Cycles" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                    elif ("Output Transfer Time" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                    elif ("Output Transfer Cycles" in line):
                        val = line.split(':')[-1]
                        val = val.split('\n')[0]
                        entry = entry+","+val
                logfl.close()
                file_out.write(entry+"\n")
        file_out.close()




    
    for test_name in test_list:
        cmd = 'make build_sw TARGET_DIR=' + target_dir + ' TEST_NAME=' + test_name
        print (cmd)
        os.system(cmd)


def clean():
    msg = 'Deleting '+target_dir+' '+log_dir
    print(msg)
    clean_cmd = 'rm -rf '+target_dir+' '+log_dir
    os.system(clean_cmd)
    print(clean_cmd)

if __name__ == "__main__":
    print_menu()

