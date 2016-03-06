**Backtracing**

1. Top of the stack:
 
        (gdb) bt

1. Bottom of the stack:

        (gdb) bt -1000

1. Include local variables in backtrace:

        (gdb) bt full


---

**Logging**

1. Log to default file (``gdb.txt``):

        (gdb) set logging on
        
2. Turn off output pagination (for logging long backtraces):

        (gdb) set pagination off


---



**gdb and QEMU**

1. Setting the args once for the session:

        (gdb) set args -hda ../debian.qcow2 -vnc :0  -panda-plugin panda_prov_tracer.so -panda-arg panda_prov_tracer:guest=linux-i686 -replay foorec

1.  Handling SIGUSR1/SIGUSR2. These are used to signal guest to increment timet:

        (gdb) handle SIGUSR1 pass noprint
        Signal        Stop	Print	Pass to program	Description
        SIGUSR1       No	No	Yes		User defined signal 1
        (gdb) handle SIGUSR2 pass noprint
        Signal        Stop	Print	Pass to program	Description
        SIGUSR2       No	No	Yes		User defined signal 2

---

**Resources**

* [GDB Wiki - FAQ ](https://sourceware.org/gdb/wiki/FAQ)
