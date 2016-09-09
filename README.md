# Slack-Driven Dual-Vth Assignment

A new TCL command to be integrated within Design Compiler that performs a Slack-driven Dual-Vth postsynthesis optimization. Such a command reduces leakage power by means of dual-Vth assignment while forcing the number of quasi-critical paths below a user-defined constraint.

Main arguments of the command are:
         -arrivalTime: the actual timing constraint the circuit has to satisfy after dual-Vth assignment [ns]
         -criticalPaths: the total number of timing paths that fall within a given slack window after the dual-Vth assignment [integer]
          -slackWin: is the slack window for critical paths [ns]

The command returns the list resList containing the following 4 items
         item 0--> power-savings: % of leakage reduction w.r.t. the initial configuration; 
         item 1--> execution-time: difference between starting-time and end-time [seconds].
         item 2--> lvt: % of LVT gates
         item 3--> hvt: % of HVT gates
  
SYNOPSIS
    
        $resList$ leakage_opt –arrivalTime $at$ -criticalPaths $num$ -slackWin $time$

