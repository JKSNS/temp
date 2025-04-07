alert tcp $EXTERNAL_NET any -> $HOME_NET 80 (
    msg:"LOIC HTTP GET flood detected - alert";
    flow:to_server,established;
    content:"GET";
    detection_filter: track by_src, count 10, seconds 1;
    reference:url,https://en.wikipedia.org/wiki/Low_Orbit_Ion_Cannon;
    sid:1000001;
    rev:1;
)
