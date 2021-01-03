
BOARD ?= avr

# final binary name
PROGRAM = valzer
# output dir
OUT_DIR = out
OUT_DIR_BOARD = $(OUT_DIR)/$(BOARD)

CC = gcc
OC = objcopy
CFLAGS = -D__BOARD_$(shell echo $(BOARD) | tr a-z A-Z)__ -I./include -I./include/$(BOARD) -Wall -g -Os
ifeq ($(BOARD),avr)
	CC = avr-gcc
	OC = avr-objcopy
        CFLAGS += -mmcu=atmega2560 -DF_CPU=16000000
else
	CFLAGS += -lutil
endif
ASFLAGS = ${CFLAGS}

BOARD_DIR = $(BOARD)

# common
ifeq ($(BOARD),avr)
SRCS_COMMON_DEFAULT = sched.c cmds_base.c cmds_debug.c rxtx_irq.c
else
SRCS_COMMON_DEFAULT = sched.c cmds_base.c cmds_debug.c rxtx_irq.c generic_crc16_ccitt.c generic_dynpool.c
endif
SRCS_COMMON_GPIO = initial_pins.c cmds_gpio.c
SRCS_COMMON_GPIO_ADC = cmds_adc.c
SRCS_COMMON_GPIO_SPI = cmds_spi.c
SRCS_COMMON_GPIO_I2C = cmds_i2c.c
SRCS_COMMON_GPIO_PWM = cmds_pwm.c
SRCS_COMMON_GPIO_BITBANGING = cmds_bitbanging.c
SRCS_COMMON = $(SRCS_COMMON_DEFAULT) \
	      $(SRCS_COMMON_GPIO) \
	      $(SRCS_COMMON_GPIO_ADC) \
	      $(SRCS_COMMON_GPIO_SPI) \
	      $(SRCS_COMMON_GPIO_I2C) \
	      $(SRCS_COMMON_GPIO_PWM) \
	      $(SRCS_COMMON_GPIO_BITBANGING)

# board specific
ifeq ($(BOARD),avr)
SRCS_BOARD_DEFAULT = prescaler.c timer.c console.c crc16_ccitt.c dynpool.c
else
SRCS_BOARD_DEFAULT = irq.c timer.c console.c
endif
SRCS_BOARD_GPIO = gpio.c
SRCS_BOARD_GPIO_ADC = adc.c
SRCS_BOARD_GPIO_SPI = spi.c
SRCS_BOARD_GPIO_I2C = i2c.c
SRCS_BOARD_GPIO_PWM = pwm.c
SRCS_BOARD_WATCHDOG = watchdog.c
ifeq ($(BOARD),avr)
SRCS_BOARD_SERIAL = serial.c
else
SRCS_BOARD_SERIAL = 
endif
SRCS_BOARD = $(SRCS_BOARD_DEFAULT) \
	   $(SRCS_BOARD_GPIO) \
	   $(SRCS_BOARD_GPIO_ADC) \
	   $(SRCS_BOARD_GPIO_SPI) \
	   $(SRCS_BOARD_GPIO_I2C) \
	   $(SRCS_BOARD_GPIO_PWM) \
	   $(SRCS_BOARD_WATCHDOG) \
	   $(SRCS_BOARD_SERIAL)

# These are the object files that gcc will create, from your .c files
# you need one for each of your C source files
OBJS_COMMON = $(SRCS_COMMON:%.c=$(OUT_DIR_BOARD)/%.o)
OBJS_BOARD = $(SRCS_BOARD:%.c=$(OUT_DIR_BOARD)/$(BOARD_DIR)/%.o)

# Any other files that aren't C source, that trigger a rebuild
DEPS_COMMON = cmd.h \
		cmds_adc.h \
		cmds_base.h \
		cmds_bitbanging.h \
		cmds_debug.h \
		cmds_gpio.h \
		cmds_i2c.h \
		cmds_pwm.h \
		cmds_spi.h \
		generic_gpio.h \
		generic_io.h \
		generic_irq.h \
		generic_pgm.h \
		initial_pins.h \
		macro_byteorder.h \
		macro_compiler.h \
		protocol.h \
		rxtx_irq.h \
		sched.h \
		timer_irq.h

DEPS_BOARD = autoconf.$(BOARD).h
ifeq ($(BOARD),avr)
DEPS_BOARD += adc.h \
		console.h \
		crc16_ccitt.h \
		dynpool.h \
		gpio.h \
		i2c.h \
		internal.h \
		irq.h \
		pgm.h \
		prescaler.h \
		pwm.h \
		serial.h \
		spi.h \
		timer.h \
		watchdog.h
else
DEPS_BOARD += console.h
endif

# "make all" creates a burnable hex file
ifeq ($(BOARD),avr)
all: $(PROGRAM).$(BOARD).hex
else
all: $(PROGRAM).$(BOARD).elf
endif

# this turns the .elf binary into .hex for avrdude
$(PROGRAM).avr.hex: $(PROGRAM).$(BOARD).elf
	$(OC) -j .text -j .data -O ihex $(OUT_DIR_BOARD)/$< $@

# this builds and links the .o files into a .elf binary
$(PROGRAM).$(BOARD).elf: $(OBJS_COMMON) $(OBJS_BOARD) $(OUT_DIR_BOARD)/main.$(BOARD).o
	$(CC) $(CFLAGS) -o $(OUT_DIR_BOARD)/$@ $^
ifneq ($(BOARD),avr)
	cp $(OUT_DIR_BOARD)/$@ .
endif

# this compiles the .c files into .o files
$(OUT_DIR_BOARD)/%.o: src/%.c $(DEPS_COMMON:%.h=include/%.h)
	$(CC) $(CFLAGS) -o $@ -c $<
$(OUT_DIR_BOARD)/$(BOARD_DIR)/%.o: src/$(BOARD_DIR)/%.c $(DEPS_BOARD:%.h=include/$(BOARD_DIR)/%.h)
	$(CC) $(CFLAGS) -o $@ -c $<

burn: $(PROGRAM).avr.hex
	avrdude -patmega2560 -cwiring -P/dev/ttyUSB0 -b115200 -D -Uflash:w:$(PROGRAM).$(BOARD).hex:i

clean:
	rm $(OBJS_COMMON) $(OBJS_BOARD) $(OUT_DIR_BOARD)/main.$(BOARD).o
	rm $(OUT_DIR_BOARD)/$(PROGRAM).$(BOARD).elf
ifeq ($(BOARD),avr)
	rm $(PROGRAM).$(BOARD).hex
else
	rm $(PROGRAM).$(BOARD).elf
endif

