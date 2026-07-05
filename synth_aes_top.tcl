#######################################################################
# Genus Synthesis Script — AES-128 (aes_top)
# Target Library : GPDK090 (Cadence Generic PDK, 90nm, digital)
# Run with       : genus -files synth_aes_top.tcl   (or source inside genus shell)
#######################################################################

# ---------------------------------------------------------------------
# 1. Library Setup
# ---------------------------------------------------------------------
set LIB_PATH  /home/patna/cadence/FOUNDRY/digital/90nm/dig/lib
set_db library ${LIB_PATH}/typical.lib

# ---------------------------------------------------------------------
# 2. Read RTL Sources (aes_top and its 12 dependent modules)
#    NOTE: AXI wrapper / AXI testbench are intentionally excluded —
#    ASIC target is the pure AES-128 core only.
# ---------------------------------------------------------------------
set RTL_DIR /home/student8/Deepak/AES-128/rtl

read_hdl -sv [list \
    ${RTL_DIR}/sbox.v \
    ${RTL_DIR}/inv_sbox.v \
    ${RTL_DIR}/shift_rows.v \
    ${RTL_DIR}/inv_shift_rows.v \
    ${RTL_DIR}/mix_columns.v \
    ${RTL_DIR}/inv_mix_columns.v \
    ${RTL_DIR}/add_round_key.v \
    ${RTL_DIR}/sub_bytes.v \
    ${RTL_DIR}/inv_sub_bytes.v \
    ${RTL_DIR}/key_expansion.v \
    ${RTL_DIR}/aes_encrypt.v \
    ${RTL_DIR}/aes_decrypt.v \
    ${RTL_DIR}/aes_top.v \
]

elaborate aes_top

# ---------------------------------------------------------------------
# 3. Timing Constraints
#    100 MHz target (10 ns period) — comfortably achievable in 90nm ASIC
#    standard cells even for the combinational-heavy iterative round path.
# ---------------------------------------------------------------------
create_clock -name CLK -period 10.0 [get_ports clk]

set_clock_uncertainty 0.2 [get_clocks CLK]
set_input_delay  2.0 -clock CLK [remove_from_collection [all_inputs]  [get_ports clk]]
set_output_delay 2.0 -clock CLK [all_outputs]

# Reset is asynchronous / not clock-related for timing purposes
set_false_path -from [get_ports rst]

# ---------------------------------------------------------------------
# 4. Synthesis
# ---------------------------------------------------------------------
set_db syn_generic_effort   medium
set_db syn_map_effort       high
set_db syn_opt_effort       high

syn_generic
syn_map
syn_opt

# ---------------------------------------------------------------------
# 5. Reports
# ---------------------------------------------------------------------
report_timing              > reports/aes_top_timing.rpt
report_area                > reports/aes_top_area.rpt
report_power                > reports/aes_top_power.rpt
report_gates                > reports/aes_top_gates.rpt

# ---------------------------------------------------------------------
# 6. Output — gate-level netlist + SDC for Innovus
# ---------------------------------------------------------------------
write_hdl                  > outputs/aes_top_netlist.v
write_sdc                  > outputs/aes_top.sdc
write_db aes_top_genus.db  -to_dir outputs/genus_db

puts "Genus synthesis complete. Check reports/ for timing, area, power."
