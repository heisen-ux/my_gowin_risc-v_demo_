################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/irq.c \
../src/loader.c \
../src/main.c 

S_UPPER_SRCS += \
../src/custom_ops.S \
../src/start.S 

OBJS += \
./src/custom_ops.o \
./src/irq.o \
./src/loader.o \
./src/main.o \
./src/start.o 

S_UPPER_DEPS += \
./src/custom_ops.d \
./src/start.d 

C_DEPS += \
./src/irq.d \
./src/loader.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.S src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv-none-elf-gcc -march=rv32imc_zicsr -mabi=ilp32 -mtune=size -mcmodel=medany -msmall-data-limit=8 -mstrict-align -msave-restore -O0 -fmessage-length=0 -ffunction-sections -fdata-sections -fno-builtin -g -x assembler-with-cpp -Wa,-adhlns="$@.lst" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.c src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc -march=rv32imc_zicsr -mabi=ilp32 -mtune=size -mcmodel=medany -msmall-data-limit=8 -mstrict-align -msave-restore -O0 -fmessage-length=0 -ffunction-sections -fdata-sections -fno-builtin -g -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\bsp" -I"F:\ALL_PROJECT\gowin\GMD_workspace\my_1\src\lib" -std=gnu11 -Wa,-adhlns="$@.lst" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


