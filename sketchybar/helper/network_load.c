#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <mach/mach.h>
#include <time.h>

struct network {
  char interface[16];
  unsigned long long prev_rx_bytes;
  unsigned long long prev_tx_bytes;
  bool has_prev;
  double interval;
  char command[256];
};

void network_init(struct network* net, const char* iface, double interval) {
  strncpy(net->interface, iface, 15);
  net->interface[15] = '\0';
  net->prev_rx_bytes = 0;
  net->prev_tx_bytes = 0;
  net->has_prev = false;
  net->interval = interval;
  net->command[0] = '\0';
}

void network_update(struct network* net) {
  struct ifaddrs *ifaddr, *ifa;
  unsigned long long rx_bytes = 0, tx_bytes = 0;

  if (getifaddrs(&ifaddr) == -1) {
    printf("Error: Could not get interface stats.\n");
    return;
  }

  for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (strcmp(ifa->ifa_name, net->interface) == 0 && ifa->ifa_addr->sa_family == AF_LINK) {
      struct if_data *ifd = (struct if_data*)ifa->ifa_data;
      rx_bytes = ifd->ifi_ibytes;
      tx_bytes = ifd->ifi_obytes;
      break;
    }
  }

  freeifaddrs(ifaddr);

  if (net->has_prev) {
    double rx_diff = (rx_bytes - net->prev_rx_bytes) / net->interval;
    double tx_diff = (tx_bytes - net->prev_tx_bytes) / net->interval;

    char rx_str[16], tx_str[16];
    if (rx_diff < 1024) snprintf(rx_str, 16, "%.0f Bps", rx_diff);
    else if (rx_diff < 1024*1024) snprintf(rx_str, 16, "%.1f KBps", rx_diff/1024);
    else snprintf(rx_str, 16, "%.1f MBps", rx_diff/(1024*1024));

    if (tx_diff < 1024) snprintf(tx_str, 16, "%.0f Bps", tx_diff);
    else if (tx_diff < 1024*1024) snprintf(tx_str, 16, "%.1f KBps", tx_diff/1024);
    else snprintf(tx_str, 16, "%.1f MBps", tx_diff/(1024*1024));

    snprintf(net->command, 256, "sketchybar --set wifi.upload label=\"%s\" --set wifi.download label=\"%s\"",
             tx_str, rx_str);
    system(net->command);
  }

  net->prev_rx_bytes = rx_bytes;
  net->prev_tx_bytes = tx_bytes;
  net->has_prev = true;
}

int main(int argc, char* argv[]) {
  if (argc != 3) {
    printf("Usage: %s <interface> <interval>\n", argv[0]);
    return 1;
  }

  struct network net;
  network_init(&net, argv[1], atof(argv[2]));

  while (1) {
    network_update(&net);
    usleep(net.interval * 1000000);
  }

  return 0;
}