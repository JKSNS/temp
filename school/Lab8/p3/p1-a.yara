alert tcp $EXTERNAL_NET any -> $HOME_NET 80 (
    msg:"HTTP access to httpforever.com detected";
    flow:to_server,established;
    http_header;
    content:"Host|3A| httpforever.com";
    sid:3000001;
    rev:1;
)
