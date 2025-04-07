alert udp any any -> $HOME_NET 123 (
    msg:"NTP traffic detected";
    reference:url,https://en.wikipedia.org/wiki/Network_Time_Protocol;
    sid:2000007;
    rev:1;
)
