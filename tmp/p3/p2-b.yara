alert tcp any any -> $HOME_NET 23 (
    msg:"Live capture: Telnet session initiated";
    flow:to_server,established;
    content:"Telnet";
    sid:3000003;
    rev:1;
)
