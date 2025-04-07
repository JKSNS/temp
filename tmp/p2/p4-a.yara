alert udp any any -> $HOME_NET 53 (
    msg:"DNS query detected";
    reference:url,https://www.iana.org/domains/root;
    sid:2000006;
    rev:1;
)
