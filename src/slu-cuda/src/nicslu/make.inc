CC = icpx
AR = ar -r
RANLIB = ranlib
MACROS = -DNO_ATOMIC -DSSE2
CFLAGS = -fPIE -c -g -O2 -Wall -Wextra -msse2 $(MACROS)
LFLAGS = 
