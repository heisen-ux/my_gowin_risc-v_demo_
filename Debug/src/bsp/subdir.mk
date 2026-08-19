################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bsp/simpleuart.c \
../src/bsp/wbgpio.c \
../src/bsp/wbi2c.c \
../src/bsp/wbspi.c \
../src/bsp/wbspiflash.c \
../src/bsp/wbuart.c 

OBJS += \
./src/bsp/simpleuart.o \
./src/bsp/wbgpio.o \
./src/bsp/wbi2c.o \
./src/bsp/wbspi.o \
./src/bsp/wbspiflash.o \
./src/bsp/wbuart.o 

C_DEPS += \
./src/bsp/simpleuart.d \
./src/bsp/wbgpio.d \
./src/bsp/wbi2c.d \
./src/bsp/wbspi.d \
./src/bsp/wbspiflash.d \
./src/bsp/wbuart.d 


# Each subdirectory must supply rules for building sources it contributes
src/bsp/%.o: ../src/bsp/%.c src/bsp/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc -march=rv32imc_zicsr -mabi=ilp32 -mtune=size -mcmodel=medany -msmall-data-limit=8 -mstrict-align -msave-restore -O0 -fmessage-length=0 -ffunction-sections -fdata-sections -fno-builtin -g -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\bsp" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\lib" -std=gnu11 -Wa,-adhlns="$@.lst" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


