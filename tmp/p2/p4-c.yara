alert udp any any -> $HOME_NET 161 (
    msg:"SNMP traffic detected";
    reference:url,https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol;
    sid:2000008;
    rev:1;
)
