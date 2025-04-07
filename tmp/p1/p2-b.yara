drop icmp any any -> $HOME_NET any (
    msg:"Ping of Death detected - block";
    dsize:!0-60000;
    reference:url,https://en.wikipedia.org/wiki/Ping_of_death;
    sid:1000004;
    rev:1;
)
