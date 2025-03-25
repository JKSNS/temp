rule match_366lab
{
    meta:
        description = "Megatron"
        author = "Jackson"
        date = "2025-03-25"

    strings:
        $byu = "www.byu.edu"
        $ocsp = "OCSP response"
        $ping_reply = "1.1.1.1"

    condition:
        any of them
}

rule match_ping_pcap
{
    meta:
        description = "Bumblebee"
        author = "Jackson"
        date = "2025-03-25"

    strings:
        $google_dns = "8.8.8.8"
        $glunz = "GlunzJensen"
        $udp_traffic = "UDP"

    condition:
        any of them
}

rule match_both
{
    meta:
        description = "Evil Larry"
        author = "Jackson"
        date = "2025-03-25"

    strings:
        $ping_word = "ping"

    condition:
        $ping_word
}
