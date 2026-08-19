all:
	gcc -DDEBUG -o gpad-daemon gpad-daemon.c gamepad.c -framework Foundation -framework IOKit

