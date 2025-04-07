alert tcp 10.42.124.0/22 any -> any 25 (
    msg:"Alert: Swoop attempting to email the chocolate milk formula";
    flow:to_server,established;
    content:"Cosmo's Super-Secret Chocolate Milk Formula";
    reference:url,https://en.wikipedia.org/wiki/Email;
    sid:1000005;
    rev:1;
)
