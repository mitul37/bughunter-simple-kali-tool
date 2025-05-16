interface=wlan0                     # Replace with your interface (eth0 or wlan0)
dhcp-range=192.168.0.50,192.168.0.150,12h
address=/#/192.168.0.119            # Redirect ALL domains to your Kali IP
log-queries
log-dhcp
