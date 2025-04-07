alert tcp any any -> $HOME_NET 21 (
    msg:"Live capture: FTP login attempt detected";
    flow:to_server,established;
    content:"USER";
    sid:3000002;
    rev:1;
)
