alert icmp any any -> $HOME_NET any (
    msg:"Ping of Death detected - alert";
    dsize:!0-60000;
    reference:url,https://en.wikipedia.org/wiki/Ping_of_death;
    sid:1000003;
    rev:1;
)
