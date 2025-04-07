drop tcp $EXTERNAL_NET any -> $HOME_NET 80 (
    msg:"LOIC HTTP GET flood blocked - drop";
    flow:to_server,established;
    content:"GET";
    detection_filter: track by_src, count 10, seconds 1;
    reference:url,https://en.wikipedia.org/wiki/Low_Orbit_Ion_Cannon;
    sid:1000002;
    rev:1;
)
