#!/bin/sh
#
# Start es bmc daemon
# bind ttyS2 irq to cpu1~cpu3 since cpu0 is busy
#

case "$1" in
 start)
	echo "Starting eswin bmc daemon..."
	/usr/bin/es-bmcd
	sleep 1
	# writing value 14 (1110), cpu1~cpu3
	echo 14 > /proc/irq/14/smp_affinity # Decimal value
	echo e  > /proc/irq/14/smp_affinity # Hex value since some kernel accepts hex value
	;;
  stop)
    echo "Stopping eswin bmc daemon..."
    pkill -x "es-bmcd"
    if [ $? -eq 0 ]; then
        echo "eswin bmc daemon stopped successfully."
    else
        echo "Failed to stop eswin bmc daemon."
    fi
	;;
  restart|reload)
    $0 stop
    $0 start
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

