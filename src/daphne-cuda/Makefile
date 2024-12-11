# Not original Makefile!
# Original Makefile is in src/points2image/Makefile
# This Makefile is for the build script only

#===============================================================================
# User Options
#===============================================================================

# Compiler can be set below, or via environment variable
CC        = nvcc
OPTIMIZE  = yes
DEBUG     = no
ARCH      = sm_60
LAUNCHER  =

#===============================================================================
# Program name & source code list
#===============================================================================

program = main

source = src/common/main.cpp src/points2image/kernel.cu

obj = main.o kernel.o

#===============================================================================
# Sets Flags
#===============================================================================

# Standard Flags
CFLAGS := $(EXTRA_CFLAGS) -std=c++14 -Xcompiler -Wall -arch=$(ARCH) -I./src/include

# Linker Flags
LDFLAGS = 

# Debug Flags
ifeq ($(DEBUG),yes)
  CFLAGS += -g -DDEBUG
  LDFLAGS  += -g
endif

# Optimization Flags
ifeq ($(OPTIMIZE),yes)
  CFLAGS += -O3
endif
#===============================================================================
# Targets to Build
#===============================================================================
all: $(program) checkdata

$(program): $(obj) Makefile
	$(CC) $(CFLAGS) $(obj) -o $@ $(LDFLAGS)

kernel.o: src/points2image/kernel.cu src/points2image/datatypes.h src/include/benchmark.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

main.o: src/common/main.cpp src/include/benchmark.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

checkdata:
ifeq ($(wildcard data/p2i_input.dat),)
	$(warning p2i_input.dat not found. Did you forget to extract the test data?)
endif
ifeq ($(wildcard data/p2i_output.dat),)
	$(warning p2i_output.dat not found. Did you forget to extract the test data?)
endif

clean:
	rm -rf $(program) $(obj)

# TODO: when p > 1, results mismatch
run: $(program)
	$(LAUNCHER) ./$(program) -p 1
