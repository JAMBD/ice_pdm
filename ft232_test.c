#include <termios.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <errno.h>
#include <pthread.h>
#include <time.h>

#define BAUDRATE B4000000
#define SERIAL_DEVICE "/dev/ttyUSB1"


void main()
{
    int fd, res;
    struct termios old_tty;
    struct termios tty;
    struct sigaction saio;

    fd = open(SERIAL_DEVICE, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd <0) {
        perror(SERIAL_DEVICE);
        exit(-1);
    }

    // Set up serial port.
    if (tcgetattr (fd, &tty) != 0)
    {
        printf ("error %d from tcgetattr", errno);
    }

    cfsetospeed (&tty, BAUDRATE);
    cfsetispeed (&tty, BAUDRATE);

    tty.c_cc[VMIN]  = 0;
    tty.c_cc[VTIME] = 5;

    tty.c_cflag |= (CLOCAL | CREAD);

    // NO MAPPING!
    tty.c_iflag &= ~(IGNBRK | IGNCR | ICRNL | IUCLC);

    // No SW flow control
    tty.c_iflag &= ~(IXON | IXOFF | IXANY);

    // Raw input
    tty.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);

    // No HW flow control
    tty.c_cflag &= ~CRTSCTS;

    // 8N1
    tty.c_cflag &= ~(PARENB | PARODD | CSTOPB);
    tty.c_cflag |= CS8;

    if (tcsetattr (fd, TCSANOW, &tty) != 0)
    {
        printf ("error %d from tcsetattr", errno);
    }   

    u_int8_t bytes[256];

    int total_w = 0;
    int total_r = 0;

    for (int i=0; i<sizeof(bytes); i++){
        bytes[i] = 0x0d;
    }

    int w = write(fd, bytes, sizeof(bytes));
    total_w += w;
    for (int i=0; i<sizeof(bytes);){
        int r = read(fd, bytes, sizeof(bytes)-i);
        if (r < 0) continue;
        i += r;
        total_r += r;
    }

    int errors = 0;
    for (int i=0; i<sizeof(bytes); i++){
        if (bytes[i] != 0x0d){
            printf("byte %d = 0x%02X\n", i, bytes[i]);
            errors ++;
        }
    }

    printf("%d written, %d read, %d errors\n", total_w, total_r, errors);

    close(fd);
}
