/**
 * This is an implementation of Backpressure based routing over BLIP,
 * based on the concepts in the Backpressure collection protocol
 *
 * @author Srikanth Nori <snori@usc.edu>
 */

#include <IPDispatch.h>
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/ip.h>
#include <BlipStatistics.h>

#define SENDER_EXPR (TOS_NODE_ID != 1)
#define DEST_NODE_ID 1
#define DEST_ADDR "fe80::212:6d4c:4f00:1"

module TossimBlipP {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;
		interface SplitControl as IPControl;

		interface UDP as UDPRecv;
		interface UDP as UDPSend;

		interface Leds;

		interface Timer<TMilli> as SendTimer;
		interface RootControl;
	}

} implementation {

	struct sockaddr_in6 route_dest;
#define BUFLEN 4
	uint8_t buf[BUFLEN];
	uint32_t ctr;

	event void Boot.booted()
	{
		ctr = TOS_NODE_ID * 1000;


		call RadioControl.start();
		call IPControl.start();

		if(TOS_NODE_ID == DEST_NODE_ID)
		{
			dbg("Boot", "Setting root\n");
			call RootControl.setRoot();
		}
		dbg("Boot", "booted: %i\n", TOS_NODE_ID);

		call UDPRecv.bind(7000);
	}

	event void RadioControl.startDone(error_t e) {
	}

	event void RadioControl.stopDone(error_t e) {

	}

	uint32_t now, t0, dt;
	bool first_timer = TRUE;
	event void IPControl.startDone (error_t error)
	{
		if(SENDER_EXPR) {
		now = call SendTimer.getNow();
		t0 = now + 5000;
		//t0 = INTER_PKT_TIME;
		dt = INTER_PKT_TIME;
		dbg("TossimBlip", "now: %u, t0: %u, dt: %u\n", now, t0, dt);
		call SendTimer.startOneShot(t0);
		}
	}

	event void IPControl.stopDone (error_t error) { }

	event void UDPSend.recvfrom(struct sockaddr_in6 *from, void *data,
			uint16_t len, struct ip6_metadata *meta) {

	}

	uint32_t pkts_recvd = 0;
	event void UDPRecv.recvfrom(struct sockaddr_in6 *from, void *data,
			uint16_t len, struct ip6_metadata *meta)
	{
		char addr[46];
		uint32_t rec = 0;
		uint8_t *ptr = data;
		rec = (((uint32_t)ptr[0] << 24) |
				((uint32_t)ptr[1] << 16) |
				((uint32_t)ptr[2] << 8) |
				(uint32_t)ptr[3]);
		call Leds.led1Toggle();
		inet_ntop6(&from->sin6_addr, addr, 46);
		dbg("TossimBlip", "%i received a packet %u from %s\n", TOS_NODE_ID, rec, addr);
		pkts_recvd ++;
	}

	event void SendTimer.fired() {
		int ret;
		if(SENDER_EXPR) {
			buf[0] = (ctr & 0xff000000) >> 24;
			buf[1] = (ctr & 0xff0000) >> 16;
			buf[2] = (ctr & 0xff00) >> 8;
			buf[3] = (ctr & 0xff);

			route_dest.sin6_port = htons(7000);
			inet_pton6(DEST_ADDR, &route_dest.sin6_addr);
			dbg("TossimBlip", "%i sending a packet [%u] to %s\n", TOS_NODE_ID, ctr, DEST_ADDR);
			ctr++;
			while(1) {
				ret = call UDPSend.sendto(&route_dest, &buf, BUFLEN);

				if(ret == SUCCESS) {
					dbg("TossimBlip", "Sending packet success\n");
					break;
				} else if (ret == ERETRY) {
					dbg("TossimBlip", "retrying...\n");
					continue;
				} else {
					dbg("TossimBlip", "Sending packet failed %d\n", ret);
					break;
				}

			}
			call Leds.led0Toggle();

			if(first_timer) {
				first_timer = FALSE;
				call SendTimer.stop();
				call SendTimer.startPeriodic(dt);
			}
		}
		return;
	}
}
