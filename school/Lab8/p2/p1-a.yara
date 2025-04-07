log tcp any any -> $HOME_NET any (
    msg:"TCP SYN request logged";
    flags:S;
    reference:url,https://docs.snort.org/;
    sid:2000001;
    rev:1;
)
