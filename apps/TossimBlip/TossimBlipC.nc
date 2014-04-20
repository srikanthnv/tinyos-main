/**
 * @author Srikanth Nori <snori@usc.edu>
 */

#include <lib6lowpan/6lowpan.h>
#include "TossimBlip.h"

configuration TossimBlipC {

} implementation {
	components MainC, LedsC;
	components TossimBlipP;

	TossimBlipP.Boot -> MainC;
	TossimBlipP.Leds -> LedsC;

	components new TimerMilliC() as SendT;
	TossimBlipP.SendTimer -> SendT;
	components IPStackC;

	TossimBlipP.RadioControl ->  IPStackC;
	components new UdpSocketC() as UDPRecv,
						 new UdpSocketC() as UDPSend;
	TossimBlipP.UDPRecv -> UDPRecv;

	TossimBlipP.UDPSend -> UDPSend;

	components RPLRoutingC;
	TossimBlipP.RootControl -> RPLRoutingC;

	TossimBlipP.IPControl -> IPStackC;

#ifndef IN6_PREFIX
	components DhcpCmdC;
#endif

#ifdef PRINTFUART_ENABLED
	/* This component wires printf directly to the serial port, and does
	 * not use any framing.  You can view the output simply by tailing
	 * the serial device.  Unlike the old printfUART, this allows us to
	 * use PlatformSerialC to provide the serial driver.
	 *
	 * For instance:
	 * $ stty -F /dev/ttyUSB0 115200
	 * $ tail -f /dev/ttyUSB0
	 */
	//components SerialPrintfC;

	/* This is the alternative printf implementation which puts the
	 * output in framed tinyos serial messages.  This lets you operate
	 * alongside other users of the tinyos serial stack.
	 */
#if !TOSSIM
	components PrintfC;
	components SerialStartC;
#endif
#endif
}
