alert ip 220.123.102.178 any -> 10.10.10.10 any (
    msg:"Traffic detected from 220.123.102.178 to 10.10.10.10";
    sid:2000009;
    rev:1;
)
