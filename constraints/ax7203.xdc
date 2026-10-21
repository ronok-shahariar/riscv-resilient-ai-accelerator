# Constraints for ALINX AX7203 Board (Artix-7 XC7A200T)
# System Clock: 200 MHz Differential Oscillator

set_property PACKAGE_PIN R4 [get_ports clk_p]
set_property PACKAGE_PIN T4 [get_ports clk_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_n]

create_clock -period 5.000 -name sys_clk [get_ports clk_p]

# Reset Push Button (Active Low - Core Board Button connected to T6 on Bank 34)
set_property PACKAGE_PIN T6 [get_ports resetn]
set_property IOSTANDARD LVCMOS15 [get_ports resetn]

# CPU Trap Status LED (Mapped to Carrier Board LED1 on pin B13)
set_property PACKAGE_PIN B13 [get_ports trap]
set_property IOSTANDARD LVCMOS33 [get_ports trap]

# UART TX Pin (Connected to CP2102 UART bridge)
set_property PACKAGE_PIN N15 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]