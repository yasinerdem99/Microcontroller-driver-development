################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../MyDriversErdem/Src/EXTI.c \
../MyDriversErdem/Src/GPIO.c \
../MyDriversErdem/Src/RCC.c \
../MyDriversErdem/Src/SPI.c \
../MyDriversErdem/Src/USART.c 

OBJS += \
./MyDriversErdem/Src/EXTI.o \
./MyDriversErdem/Src/GPIO.o \
./MyDriversErdem/Src/RCC.o \
./MyDriversErdem/Src/SPI.o \
./MyDriversErdem/Src/USART.o 

C_DEPS += \
./MyDriversErdem/Src/EXTI.d \
./MyDriversErdem/Src/GPIO.d \
./MyDriversErdem/Src/RCC.d \
./MyDriversErdem/Src/SPI.d \
./MyDriversErdem/Src/USART.d 


# Each subdirectory must supply rules for building sources it contributes
MyDriversErdem/Src/%.o MyDriversErdem/Src/%.su MyDriversErdem/Src/%.cyclo: ../MyDriversErdem/Src/%.c MyDriversErdem/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32F407G_DISC1 -DSTM32F4 -DSTM32F407VGTx -c -I../Inc -I"C:/Users/LENOVO/Desktop/embedded/EmbeddedProjects/DriverDevelopment/MyDriversErdem/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-MyDriversErdem-2f-Src

clean-MyDriversErdem-2f-Src:
	-$(RM) ./MyDriversErdem/Src/EXTI.cyclo ./MyDriversErdem/Src/EXTI.d ./MyDriversErdem/Src/EXTI.o ./MyDriversErdem/Src/EXTI.su ./MyDriversErdem/Src/GPIO.cyclo ./MyDriversErdem/Src/GPIO.d ./MyDriversErdem/Src/GPIO.o ./MyDriversErdem/Src/GPIO.su ./MyDriversErdem/Src/RCC.cyclo ./MyDriversErdem/Src/RCC.d ./MyDriversErdem/Src/RCC.o ./MyDriversErdem/Src/RCC.su ./MyDriversErdem/Src/SPI.cyclo ./MyDriversErdem/Src/SPI.d ./MyDriversErdem/Src/SPI.o ./MyDriversErdem/Src/SPI.su ./MyDriversErdem/Src/USART.cyclo ./MyDriversErdem/Src/USART.d ./MyDriversErdem/Src/USART.o ./MyDriversErdem/Src/USART.su

.PHONY: clean-MyDriversErdem-2f-Src

