# filejuggler

makefile like execution environment in a rather early stage but already usable

Commands:
copy "targetdir" 
move "targetdir" 
unlink 
convert [du]
exists 
grep "regexp" [verbose]
age "min" "max"
not "func"
noweep "func"
rename "regexp" "to"
log "something"
match "regexp"
waitfor "func"


nonexisting commands are given to the system command interpreter
prepend the command with "noweep" to let it return always successfully

targets and dependencies
target: [dep1 dep2 dep3 ...]
specify \~noweep to let it end successfully, e.g. dep1\~noweep would always return dep1 successfully

The waitfor command is considered experimental at the moment, it allows to wait for a target to be successful. Wait time, polling interval and how many times it has to be successful in succession will be configurable but are not at the moment.

There's a example rules file in etc, please have a look at that.
