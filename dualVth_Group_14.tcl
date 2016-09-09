#########################################################################
# Leakage Optimization script, Group 14                                 #
# Students:                                                             #
#   - Andrea Floridia                                                   #
#   - Pooya Poolad                                                      #
#########################################################################


#########################################################################
#                                                                       #
#                       PROCEDURES DECLARATIONS                         #
#                                                                       #
#########################################################################



###########################################################################
# Name: lsort-indices                                                     #
# Input: list to be sorted                                                #
# Return: list containting the indices of the original list sorted        #
# Purpose:                                                                #
# This return a list of indices of a input list, ordered according to     #
# the option specified.                                                   #
# Example of usage:                                                       #
# set sorted_indices [lsort-indices -real -increasing $cell_list_leakage] #
# puts $sorted_indices                                                    #
###########################################################################
proc lsort-indices args {
    set unsortedList [lindex $args end]
    set switches [lrange $args 0 end-1]
    set pairs {}
    set i -1
    foreach el $unsortedList {
        lappend pairs [list [incr i] $el]
    }
    set result {}
    foreach el [eval lsort $switches [list -index 1 $pairs]] {
        lappend result [lindex $el 0]
    }
    set result
}

###########################################################################
# Name:   convert_to_nW                                                   #
# Input:  power to be converted                                           #
# Return: power converted                                                 #
# Purpose:                                                                #
# This command convert any value of power in the equivalent in nano watt. #
# The maximum unit allowed is watt, the minumum is pW.                    #
# It return the value in nano watt without any unit of measure.           #
###########################################################################
proc convert_to_nW {value} {

    if {[regexp {mW} $value] == 1} {

        # convert to mW
        set tmp [regsub -all {mW} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*0.000001]

    } elseif {[regexp {nW} $value] == 1} {

        # in case of nW just remove the return the value without unit of measure
        set tmp [regsub -all {nW} $value ""]
        scan $tmp %f tmp

    } elseif {[regexp {uW} $value] == 1} {

        set tmp [regsub -all {uW} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*0.001]


    } elseif {[regexp {dW} $value] == 1} {

        set tmp [regsub -all {dW} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*0.00000001]


    } elseif {[regexp {cW} $value] == 1} {

        set tmp [regsub -all {cW} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*0.000001]

    } elseif {[regexp {W} $value] == 1} {

        set tmp [regsub -all {W} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*0.000000001]

    } elseif {[regexp -all {pW} $value ""]} {

        set tmp [regsub -all {pW} $value ""]
        scan $tmp %f tmp
        set tmp [expr $tmp*1000]

    }
}


#################################################################################
# Name: cells_swapping                                                          #
# Input single cell or list of cells                                            #
# Return: always 1                                                              #
# Purpose:                                                                      #
# This command swap a cell specified in the cellname(it may be a list of cells) #
# to the type specified (LVT or HVT)                                            #
#################################################################################
proc cells_swapping {cellname type} {


    foreach cell $cellname {
        set LHS_flag 0
        set LLS_flag 0

        set ref_name_i [get_attribute $cell ref_name]

        if {[regexp {.+_LLS_.+} $ref_name_i] == 1} {
                set LLS_flag 1
        } elseif {[regexp {.+_LHS_.+} $ref_name_i] == 1} {
                set LHS_flag 1
        }

        set tmp [regsub -all {HS65_[A-Z]+_} $ref_name_i ""]

        if {$type == "LVT"} {
                if { $LHS_flag == 1} {
                        set res "CORE65LPLVT/HS65_LLS_$tmp"
                } else {
                        set res "CORE65LPLVT/HS65_LL_$tmp"
                }

        } elseif {$type == "HVT"} {

                if {$LLS_flag == 1} {
                        set res "CORE65LPHVT/HS65_LHS_$tmp"
                } else {
                        set res "CORE65LPHVT/HS65_LH_$tmp"
                }
        }

        size_cell $cell $res
    }

    return 1
}

#################################################################################
# Name: leakage_design                                                          #
# Input: void                                                                   #
# Return: leakage power of the current design                                   #
# Purpose:                                                                      #
# Compute the leakage power fo the whole design                                 #
#################################################################################
proc leakage_design {} {
    set report_text ""
    set lnr 3
    set wnr 5
    redirect -variable report_text {report_power}
    set report_text [split $report_text "\n"]
    set power_leakage [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]
    set wnr 6
    set unit_of_measure [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]

    return "$power_leakage $unit_of_measure"
}


#################################################################################
# Name: leak_power                                                              #
# Input: cell name                                                              #
# Return: leakage power of the cell specified as input                          #
# Purpose:                                                                      #
# Extract the leakage power of just one design                                  #
#################################################################################
proc leak_power {cell_name} {
    set report_text ""  ;# Contains the output of the report_power command
    set lnr 3           ;# Leakage info is in the 2nd line from the bottom
    set wnr 7           ;# Leakage info is the eighth word in the $lnr line
    redirect -variable report_text {report_power -only $cell_name -cell -nosplit}
    set report_text [split $report_text "\n"]
    return [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]
}


#################################################################################
# Name: extract_vth_percentages                                                 #
# Inputs: void                                                                  #
# Return: list containing the LVT and HVT percentages                           #
# Extract percentages of LVT and HVT.                                           #
# It returns a list of two items: LVT percentages and HVT percentages           #
#################################################################################
proc extract_vth_percentages {} {

    set report_text ""
    set lnr 13
    set wnr 2
    redirect -variable report_text {report_threshold_voltage_group}

    set res [list]
    set report_text [split $report_text "\n"]
    set perc_lvt [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]

    # if All cells are LVT or HVT return directly the 100% values without parsing
    if {[regexp {All} $perc_lvt] == 1} {
        set group_vt [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - [expr $lnr-3]]]] 0]

        if { [regexp {LVT} $group_vt] == 1 } {
            set res {1 0}
        } else {
            set res {0 1}
        }

    } else {

        set lnr 14
        set wnr 2
        set perc_hvt [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]

        #remove ( and ) from the gathered value
        set perc_hvt [regsub -all {\(} [regsub -all {\)} $perc_hvt ""] "" ]

        set perc_lvt [regsub -all {\(} [regsub -all {\)} $perc_lvt ""] "" ]

        # remove percentages from the gathered value
        set perc_hvt [regsub -all {%} $perc_hvt "" ]

        set perc_lvt [regsub -all {%} $perc_lvt "" ]

        lappend res [expr [expr $perc_lvt/10]/10.0]
        lappend res [expr [expr $perc_hvt/10]/10.0]

    }

    return $res

}


#################################################################################
# Name: check_constraint                                                        #
# Input: user_arrival_time, right_edge_slack, left_edge_slack, number_paths     #
# Return: 1 if constraints are met, 0 otherwise                                 #
# check constraint are met or not. the procedure yields true if met, or         #
# false not met.                                                                #
#################################################################################
proc check_constraint {user_arrival_time right_edge_slack left_edge_slack number_paths} {

    # Extract the arrival time for the current design
    foreach_in_collection path [get_timing_path] {
        set current_arrival_time [get_attribute $path arrival]
    #set design_slack [get_attribute $path slack]
    }

    # first check whether the current arrival time is compliant
    if { $current_arrival_time > $user_arrival_time} {

        # violation -> return false(0)
        return 0

    } elseif {[sizeof_collection [get_timing_path -slack_greater_than $right_edge_slack -slack_lesser_than $left_edge_slack -nworst [expr $number_paths+1]]] > $number_paths}  {

        # violation of number of paths in the slack window -> return false
        return 0

    } else {

        return 1

    }
}



#################################################################################
# Name: leakage_opt                                                             #
# Input:  -arrivalTime float -criticalPaths integer -slackWin float             #
# Return: list containing: power_saving(%) execution_time(s) lvt(%) hvt(%)      #
#################################################################################
proc leakage_opt {option_1 user_arrival_time option_2 critical_paths option_3 slack_window} {

    # Suppress Warning message
    suppress_message TIM-104
    suppress_message NLE-019

    # Enable dual vht
    set_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT -type string
    set_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT -type string

    # Store the starting time
    set starting_time [clock milliseconds]

    #################################
    #      Variable Declaration     #
    #################################

    # list containing indices ordered according to the  arrival time after the swapping to hvt
    set arrivals_indices [list]

    # list containing the full_name of a cell
    set full_names [list]

    # List containing the results
    set rest_list [list]

    set line "$option_1 $user_arrival_time $option_2 $critical_paths $option_3 $slack_window"
    # check whether constraints are met or not
    if {[regexp {(-arrivalTime [0-9]+\.*[0-9]* -criticalPaths \d+ -slackWin [0-9]+\.*[0-9]*)} $line  ] != 1} {
        puts $line
        puts "Wrong parameters"
        puts "Parameters Format:"
        puts " -arrivalTime X -criticalPaths Y -slackWin Z"
        set res_list {0 0 0 0}
        return $res_list
    }

    # Current Design Leakage Power
    set design_leakage [convert_to_nW [leakage_design]]

    #################################
    #       Check Constraint        #
    #################################
    puts "Checking for unfeasible conditions"

    # Extract the arrival time for the current design
    foreach_in_collection path [get_timing_path] {
        set design_arrival_time [get_attribute $path arrival]
        set design_slack [get_attribute $path slack]
    }

    # check whether the arrival time is too small with respect to the current arrival time
    if { $design_arrival_time > $user_arrival_time } {

        puts "Arrival time not feasible"
        set res_list {0 0 0 0}
        return $res_list
    }

    # now the new arrival time becomes the clock period, thus recompute the "zero" slack
    set new_zero_slack [expr [expr $design_slack+$design_arrival_time]-$user_arrival_time]

    # now the slack window is [new_zero_slack ; new_zero_slack + slack_window]
    set right_edge $new_zero_slack
    set left_edge [expr $new_zero_slack+$slack_window]

    # check whether the number of paths is feasible
    if {[sizeof_collection [get_timing_path -slack_greater_than $right_edge -slack_lesser_than $left_edge -nworst [expr $critical_paths+1]]] > $critical_paths} {

        puts "Number of critical paths unfeasible"
        set res_list {0 0 0 0}
        return $res_list
    }

    #################################
    #       Optimization Phase      #
    #################################
    puts "Starting optimization"

    puts "Swapping all cells"
    set design_cells [get_cells]
    set swap_value 0        ;# holds the number of cells that violate the timining constraint -> i.e. > user_arrival_time
    set number_of_cells [sizeof_collection $design_cells]
    foreach cell $design_cells {
        set name [get_attribute $cell full_name]
        cells_swapping $name "HVT"
    }

    if {[check_constraint $user_arrival_time $right_edge $left_edge $critical_paths] == 0} {

        puts "Constraint not met, recover"
        # Optimization phase
        # sort elements in arrivals_indices
        set tmp [list]
        foreach_in_collection cell $design_cells {
            lappend full_names [get_attribute $cell full_name]
            set arrival_cell [get_attribute [get_timing_path -through [get_attribute $cell full_name]/Z] arrival]
            lappend tmp $arrival_cell
            if {$arrival_cell > $user_arrival_time} {
                set swap_value [expr $swap_value+1]
            }
        }

        # sort indices by the arrival time of the worst critical path through that cell
        set arrivals_indices [lsort-indices -real -decreasing $tmp]


        # parameters for the optimization loop
        set l_bound     0                           ;# left bound
        set r_bound     0                           ;# right bound
        set range_swap  $swap_value                 ;# range of cells to be swapped


        # init the process
        set r_bound [expr $r_bound+$range_swap]

        # swapp all cells which violate the timing constraints
        for {set i $l_bound} {$i < $r_bound} {incr i} {

        set index [lindex $arrivals_indices $i]
        cells_swapping [lindex $full_names $index] "LVT"

        }

        # further optimize
        # if constraint met, swap cell by cell until not met, and then swap back the last cell which
        # caused the violation.
        # if constraint not met, swap cell unitl are met
        if {[check_constraint $user_arrival_time $right_edge $left_edge $critical_paths] == 1} {
            set starting_index [expr $r_bound]
            if {$starting_index < 0} {
                set starting_index 0
            }
            # constraint met
            while {[check_constraint $user_arrival_time $right_edge $left_edge $critical_paths] == 1} {

                set index [lindex $arrivals_indices $starting_index]
                cells_swapping [lindex $full_names $index] "HVT"
                set starting_index [expr $starting_index-1]
                if {$starting_index < 0} {
                    set starting_index 0
                }
            }
            cells_swapping [lindex $full_names $index] "LVT"
        } else {
            set starting_index  $r_bound
            while {[check_constraint $user_arrival_time $right_edge $left_edge $critical_paths] == 0} {
                set index [lindex $arrivals_indices $starting_index]
                cells_swapping [lindex $full_names $index] "LVT"
                set starting_index [expr $starting_index+1]
                }
            }



    }

    #################################
    #       Report results          #
    #################################
    puts "Constraint met, reporting the result"
    # gather the data from the optimized design
    set current_leakage [convert_to_nW [leakage_design]]
    set power_saving  [expr [expr [expr $design_leakage-$current_leakage]/$design_leakage]]
    # extract_vth_cell -> it will return a list of two values, extract them properly
    set percentages [list]
    set percentages [extract_vth_percentages]
    set execution_time [expr [clock milliseconds]-$starting_time ]
    set execution_time [expr [expr $execution_time/100]/10.0]
    lappend res_list $power_saving
    lappend res_list $execution_time
    lappend res_list [lindex $percentages 0]
    lappend res_list [lindex $percentages 1]
    return $res_list
}
