################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/lib/firmware.c \
../src/lib/printf.c 

OBJS += \
./src/lib/firmware.o \
./src/lib/printf.o 

C_DEPS += \
./src/lib/firmware.d \
./src/lib/printf.d 


# Each subdirectory must supply rules for building sources it contributes
src/lib/%.o: ../src/lib/%.c src/lib/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc -march=rv32imc_zicsr -mabi=ilp32 -mtune=size -mcmodel=medany -msmall-data-limit=8 -mstrict-align -msave-restore -O0 -fmessage-length=0 -ffunction-sections -fdata-sections -fno-builtin -g -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\bsp" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\lib" -std=gnu11 -Wa,-adhlns="$@.lst" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


