# open work for projects
vlib work

# compile files
vlog DSP_top_module.v  DSP_TB.v Pipeline_stage.v

# simulate testbench 

vsim -voptargs="+acc" work.DSP_tb 


add wave * 

# for the DUT internal signals 
add wave /DUT/* 


# run the simulation
 run -all
