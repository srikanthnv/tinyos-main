COMPONENT=TossimBlipC

# radio options
CFLAGS += -DCC2420_DEF_CHANNEL=26
CFLAGS += -DCC2420_DEF_RFPOWER=5

# enable dma on the radio
# PFLAGS += -DENABLE_SPI0_DMA

# you can compile with or without a routing protocol... of course,
# without it, you will only be able to use link-local communication.
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(TOSDIR)/lib/net/rpl
#PFLAGS += -DRPL_OF_MRHOF
#PFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED
PFLAGS += -DBLIP_DERIVE_SHORTADDRS
PFLAGS += -DIN6_PREFIX=\"fec0::\"

include $(MAKERULES)

