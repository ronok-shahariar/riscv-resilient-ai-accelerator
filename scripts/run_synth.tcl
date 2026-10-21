# Vivado Logical Synthesis Script
if { $argc > 0 } {
    set output_dir [lindex $argv 0]
} else {
    set output_dir "vivado_outputs/vivado_build_fallback"
    file mkdir $output_dir
}

cd $output_dir
puts "INFO: Running synthesis inside: [pwd]"

read_verilog ../../rtl/cpu/picorv32.v
read_verilog ../../rtl/accelerator/int8_mac.v
read_verilog ../../rtl/accelerator/int8_mac_mmio.v
read_verilog ../../rtl/memory/bram_16kb.v
read_verilog ../../rtl/soc/uart_tx.v
read_verilog ../../rtl/soc/soc_top.v
read_xdc ../../constraints/ax7203.xdc

synth_design -top soc_top -part "xc7a200tfbg484-2"
write_checkpoint -force "post_synth.dcp"
report_utilization -file "synth_utilization.rpt"
report_timing_summary -file "synth_timing.rpt"

opt_design
place_design
route_design
write_checkpoint -force "post_route.dcp"
report_utilization -file "route_utilization.rpt"
report_timing_summary -file "route_timing.rpt"

puts "Vivado logical synthesis completed successfully."
exit
