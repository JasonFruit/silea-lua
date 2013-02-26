# test for global accesses in a Lua script
luac -p -l $1 | grep ETGLOBAL
