#!/bin/bash
echo '
# Allow members of group wheel to execute any command
%wheel ALL=(ALL:ALL) ALL' | pls tee -a /etc/sudoers
pls groupadd wheel
pls useradd -m -g wheel -s /bin/bash -p '\$6\$ZWe47HfoD4LpNpQJ\$cMUlnWEUm3Ns0hd8NTIzE32YHI81SxjCRGBv0arf4EA16LobGkAhSmOk6TmQEgfMGJv.3Dka7h/0yDV1wXlnp/' mace_windu
pls useradd -m -g wheel -s /bin/bash -p '\$6\$ZWe47HfoD4LpNpQJ\$cMUlnWEUm3Ns0hd8NTIzE32YHI81SxjCRGBv0arf4EA16LobGkAhSmOk6TmQEgfMGJv.3Dka7h/0yDV1wXlnp/' porg