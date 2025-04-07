alert tcp any any -> $HOME_NET any (
    msg:"Possible SYN flood attack detected - more than 8 SYNs per second";
    flags:S;
    detection_filter: track by_src, count 9, seconds 1;
    reference:url,https://docs.snort.org/;
    classtype:attempted-dos;
    sid:2000002;
    rev:1;
)
