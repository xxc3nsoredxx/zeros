source /usr/lib/peda/peda.py

define hook-stop
peda context reg
x/10i $eip+0xa00000
end
