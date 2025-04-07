alert udp any any -> 255.255.255.255 67 (
    msg:"DHCP Request detected: client requesting IP 192.168.1.100";
    content:"|35 01 03|";  # DHCP Message Type option (03 = DHCPREQUEST)
    content:"192.168.1.100";  # Hard-coded requested IP address
    sid:2000005;
    rev:1;
)
