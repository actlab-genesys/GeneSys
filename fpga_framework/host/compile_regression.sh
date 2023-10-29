#!/bin/bash
declare -a tests=( "resnet50_1_conv_case1" "resnet50_1_conv_case101" "resnet50_1_conv_case102" "resnet50_1_conv_case103" "resnet50_1_conv_case104" "resnet50_1_conv_case105" 
                    "resnet50_1_conv_case106" "resnet50_1_conv_case107" "resnet50_1_conv_case108" "resnet50_1_conv_case109" "resnet50_1_conv_case11" "resnet50_1_conv_case110" 
                    "resnet50_1_conv_case111" "resnet50_1_conv_case113"  "resnet50_1_conv_case114" "resnet50_1_conv_case115" "resnet50_1_conv_case116" "resnet50_1_conv_case117" 
                    "resnet50_1_conv_case118" "resnet50_1_conv_case119" "resnet50_1_conv_case120" "resnet50_1_conv_case121" "resnet50_1_conv_case123" "resnet50_1_conv_case124" 
                    "resnet50_1_conv_case126" "resnet50_1_conv_case127" "resnet50_1_conv_case128" "resnet50_1_conv_case129" "resnet50_1_conv_case13" "resnet50_1_conv_case130"
                    "resnet50_1_conv_case131" "resnet50_1_conv_case132" "resnet50_1_conv_case133" "resnet50_1_conv_case134" "resnet50_1_conv_case136" "resnet50_1_conv_case15" 
                    "resnet50_1_conv_case17" "resnet50_1_conv_case18" "resnet50_1_conv_case19" "resnet50_1_conv_case21" "resnet50_1_conv_case22" "resnet50_1_conv_case24"
                    "resnet50_1_conv_case25" "resnet50_1_conv_case26" "resnet50_1_conv_case27" "resnet50_1_conv_case29" "resnet50_1_conv_case3" "resnet50_1_conv_case30" 
                    "resnet50_1_conv_case31" "resnet50_1_conv_case32" "resnet50_1_conv_case36" "resnet50_1_conv_case37" "resnet50_1_conv_case38" "resnet50_1_conv_case39"
                    "resnet50_1_conv_case42" "resnet50_1_conv_case43" "resnet50_1_conv_case44" "resnet50_1_conv_case45" "resnet50_1_conv_case46" "resnet50_1_conv_case47"
                    "resnet50_1_conv_case48" "resnet50_1_conv_case49" "resnet50_1_conv_case5" "resnet50_1_conv_case50" "resnet50_1_conv_case51" "resnet50_1_conv_case52"
                    "resnet50_1_conv_case53" "resnet50_1_conv_case54" "resnet50_1_conv_case55" "resnet50_1_conv_case56" "resnet50_1_conv_case57" "resnet50_1_conv_case58"
                    "resnet50_1_conv_case59" "resnet50_1_conv_case60" "resnet50_1_conv_case61" "resnet50_1_conv_case62" "resnet50_1_conv_case63" "resnet50_1_conv_case64"
                    "resnet50_1_conv_case66" "resnet50_1_conv_case67" "resnet50_1_conv_case69" "resnet50_1_conv_case7" "resnet50_1_conv_case70" "resnet50_1_conv_case71"
                    "resnet50_1_conv_case72" "resnet50_1_conv_case73" "resnet50_1_conv_case74" "resnet50_1_conv_case75" "resnet50_1_conv_case76" "resnet50_1_conv_case78"
                    "resnet50_1_conv_case82" "resnet50_1_conv_case85" "resnet50_1_conv_case88" "resnet50_1_conv_case9" "resnet50_1_conv_case90" "resnet50_1_conv_case94"
                    "resnet50_1_conv_case95" "resnet50_1_conv_case96" "resnet50_1_conv_case97" "resnet50_1_conv_case98" "resnet50_1_conv_case99"
)

#for (( i=0; i<20; i++ ));
for i in "${tests[@]}"
do
  echo "\nCompiling Test: $i\n"
  #make build_sw TEST_NAME=${tests[$i]}
  make build_sw TEST_NAME=$i
done