**Create Rule 1: Matches **Both** PCAPs**

   Let’s assume the string `"TCP"` is present in both captures. A YARA rule might look like this:
   ```yara
   rule match_both_pcaps
   {
       meta:
           description = "Rule 1: Matches both PCAP files that contain 'TCP'"
           author = "YourName"
           date = "2025-03-25"

       strings:
           $tcp_string = "TCP"

       condition:
           $tcp_string
   }
   ```
   - This rule fires if it finds the literal string `TCP` anywhere in the file.  
   - Because both PCAPs have at least one TCP packet, they should both match this rule.

**Create Rule 2: Matches Only One PCAP**

   Let’s pick something that’s **unique** to `366Lab.pcap`—for instance, the domain name `"crazyngp.com"`. That way, it won’t match `PING.pcap`.  

   ```yara
   rule match_366Lab_only
   {
       meta:
           description = "Rule 2: Matches only 366Lab.pcap by searching for 'crazyngp.com'"
           author = "YourName"
           date = "2025-03-25"

       strings:
           $unique_366lab = "crazyngp.com"

       condition:
           $unique_366lab
   }
   ```
   - If you’d rather match only the `PING.pcap`, you could instead look for a unique string like `"10.37.128.9"` or `"ICMP Echo request"`. In that case, just rename the rule accordingly and swap out the string.

**Combine Both Rules in a Single `.yara` File**

   Let’s call it `myrules.yara`. You can place them back-to-back:

   ```yara
   rule match_both_pcaps
   {
       meta:
           description = "Rule 1: Matches both PCAP files that contain 'TCP'"
           author = "YourName"
           date = "2025-03-25"

       strings:
           $tcp_string = "TCP"

       condition:
           $tcp_string
   }

   rule match_366Lab_only
   {
       meta:
           description = "Rule 2: Matches only 366Lab.pcap by searching for 'crazyngp.com'"
           author = "YourName"
           date = "2025-03-25"

       strings:
           $unique_366lab = "crazyngp.com"

       condition:
           $unique_366lab
   }
   ```

5. **Run and Verify the Rules**

   In the same directory, run:
   ```bash
   # Test Rule 1 & Rule 2 on 366Lab.pcap
   yara myrules.yara 366Lab.pcap

   # Test Rule 1 & Rule 2 on PING.pcap
   yara myrules.yara PING.pcap
   ```
   - **Expected Result**:
     - **`366Lab.pcap`** should match both **`match_both_pcaps`** (because it has “TCP”) and **`match_366Lab_only`** (because it has “crazyngp.com”).  
     - **`PING.pcap`** should match **`match_both_pcaps`** only (because it has “TCP”), but **not** `match_366Lab_only`.
