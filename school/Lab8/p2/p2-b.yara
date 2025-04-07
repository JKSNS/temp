alert tcp any any -> $HOME_NET 21 (
    msg:"FTP password spraying attempt with root username";
    content:"USER root";
    classtype:attempted-recon;
    priority:1;
    reference:url,https://snort.org/documents;
    sid:2000004;
    rev:1;
)
