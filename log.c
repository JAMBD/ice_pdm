#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <inttypes.h>

int set_interface_attribs (int fd, int speed, int parity)
{
        struct termios tty;
        if (tcgetattr (fd, &tty) != 0)
        {
                printf ("error %d from tcgetattr", errno);
                return -1;
        }

        cfsetospeed (&tty, speed);
        cfsetispeed (&tty, speed);

        tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
        tty.c_iflag &= ~IGNBRK;
        tty.c_lflag = 0;
        tty.c_oflag = 0;
        tty.c_cc[VMIN]  = 0;
        tty.c_cc[VTIME] = 5;

        tty.c_iflag &= ~(IXON | IXOFF | IXANY);

        tty.c_cflag |= (CLOCAL | CREAD);
        tty.c_cflag &= ~(PARENB | PARODD);
        tty.c_cflag |= parity;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CRTSCTS;

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
        {
                printf ("error %d from tcsetattr", errno);
                return -1;
        }
        return 0;
}

void set_blocking (int fd, int should_block)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
        {
                printf ("error %x from tggetattr", errno);
                return;
        }

        tty.c_cc[VMIN]  = should_block ? 1 : 0;
        tty.c_cc[VTIME] = 5;

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
                printf ("error %d setting term attributes", errno);
}


void main(){
	char *portname = "/dev/ttyUSB1";
	int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0)
	{
		printf ("error %d opening %s: %s", errno, portname, strerror (errno));
		return;
	}

	set_interface_attribs (fd, B4000000, 0);
	set_blocking (fd, 0);

	char buf [12];
	int i;
	uint32_t audio = 0;
	uint8_t track = 0;
	int k;
	while (1){
		int n = read (fd, buf, sizeof buf);
		for (i=0; i<n; i++){
			if ((buf[i] & 0x3) == 0x0){
				if ((track & 0xF) == 0xF){
					//printf("%08" PRIx32 "\n\r", audio);
					printf("0:%u\n\r", audio);
				}
				track = 0x00;
				audio = 0x000000;
			}
			track |= 1 << (buf[i] & 0x3);
			audio |= ((uint32_t)(buf[i] >> 2) & 0x3F) << ((buf[i] & 0x3) * 6);
		}
	}
}
