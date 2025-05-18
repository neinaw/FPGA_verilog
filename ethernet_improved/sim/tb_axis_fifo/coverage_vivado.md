## Reporting Coverage in Vivado

Ref UG 937 -> SystemVerilog Feature -> Coverage

1. Set compilation options under settings -> simulation settings -> elaboration -> Set output DB to write report

tcl console:

To write data to db
```tcl
write_xsim_coverage -cov_db_dir cRun1 -cov_db_name DB1
```

To report HTML
```tcl
export_xsim_coverage -cov_db_name DB1 -cov_db_dir cRun1 -output_dir cReport1 -open_html true 
```
