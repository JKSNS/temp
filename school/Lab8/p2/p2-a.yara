alert tcp any any -> $HOME_NET 21 (
    msg:"FTP password spraying attempt with admin username";
    content:"USER admin";
    classtype:attempted-recon;
    priority:1;
    reference:url,https://snort.org/documents;
    sid:2000003;
    rev:1;
)
