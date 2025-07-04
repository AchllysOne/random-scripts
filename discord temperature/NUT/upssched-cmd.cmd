  GNU nano 7.2                                      /etc/nut/upssched-cmd                                               #!/bin/bash

case $1 in
    earlyshutdown)
        logger -t upssched-cmd "Trigger: earlyshutdown"
        /home/scripts/ups_shutdown.sh
        /usr/sbin/upsmon -c fsd
        ;;
    *)
        logger -t upssched-cmd "Unknown upssched command: $1"
        ;;
esac

