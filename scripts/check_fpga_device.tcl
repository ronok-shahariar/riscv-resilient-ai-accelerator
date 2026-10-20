puts "========================================"
puts "FIGURE 01: VIVADO AND FPGA DEVICE SUPPORT"
puts "========================================"

puts "Vivado version: [version -short]"

set parts [get_parts -filter {DEVICE == xc7a200t}]

if {[llength $parts] == 0} {
    puts "RESULT: FAIL - XC7A200T device not found"
    exit 1
}

puts "RESULT: PASS - XC7A200T device supported"
puts "Total supported variants: [llength $parts]"

puts "Available FPGA parts:"

foreach part $parts {
    puts "  $part"
}

puts "========================================"
puts "FPGA DEVICE VERIFICATION COMPLETED"
puts "========================================"
