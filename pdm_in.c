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

void serial_in (int status);

u_int8_t run = 1;

void *sendThread(void *parameters){
    int fd;
    pthread_exit(0);
}

void *readThread(void *parameters){
    int fd;
    u_int8_t data[256];
    struct timespec start, end;
    u_int32_t recv_cnt = 0;
    fd = *((int*)parameters);
    FILE* data_fd = fopen("data.raw", "wb");


    clock_gettime(CLOCK_MONOTONIC, &start);
    int bytes_read = 1;
    while (bytes_read > 0 && run){
        bytes_read = read(fd, data, 256);
        fwrite(data, sizeof(u_int8_t), bytes_read, data_fd);

        recv_cnt += bytes_read;
        if(recv_cnt > 1000000) break;
    }
    clock_gettime(CLOCK_MONOTONIC, &end);

    fclose(data_fd);

    double duration = (end.tv_sec - start.tv_sec);
    duration += (end.tv_nsec - start.tv_nsec) / 1000000000.0;
    printf("received %d bytes in %fs. %fMB/s\n", recv_cnt, duration, recv_cnt / duration / 1000000.0);
    pthread_exit(0);
}

void main()
{
    int fd, res;
    struct termios tty;
    struct sigaction saio;

    fd = open(SERIAL_DEVICE, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd <0) {
        perror(SERIAL_DEVICE);
        exit(-1);
    }

    // Setup interupt handlers.
    sigset_t block_mask;
    saio.sa_handler = serial_in;
    saio.sa_mask = block_mask;
    saio.sa_flags = 0;
    saio.sa_restorer = NULL;
    sigaction(SIGIO, &saio, NULL);

    // Allow process to recieve signals.
    fcntl(fd, F_SETOWN, getpid());
    fcntl(fd, F_SETFL, FASYNC);

    // Set up serial port.
    if (tcgetattr (fd, &tty) != 0)
    {
        printf ("error %d from tcgetattr", errno);
    }

    cfsetospeed (&tty, BAUDRATE);
    cfsetispeed (&tty, BAUDRATE);

    cfmakeraw(&tty);

    tty.c_cc[VMIN]  = 0;
    tty.c_cc[VTIME] = 5;

    // 8N1
    tty.c_cflag &= ~(PARENB | PARODD | CSTOPB);

    if (tcsetattr (fd, TCSANOW, &tty) != 0)
    {
        printf ("error %d from tcsetattr", errno);
    }   
    
    tcflush(fd, TCIFLUSH);

    pthread_t readThread_t, sendThread_t;

    pthread_create(&readThread_t, NULL, (void *)readThread, (void *)&fd);
    pthread_create(&sendThread_t, NULL, (void *)sendThread, (void *)&fd);

    pthread_join(readThread_t, NULL);   
    pthread_join(sendThread_t, NULL);

    close(fd);
}

void serial_in (int status)
{
    //printf("received SIGIO signal.\n");
}
