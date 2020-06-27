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

u_int32_t send_cnt = 0;
u_int8_t run = 1;

void delay(){
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 650 * 1000;
    nanosleep(&ts, &ts);
}

void *sendThread(void *parameters){
    int fd;
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    fd = *((int*)parameters);
    u_int8_t data[256];
    for (u_int16_t i=0; i<256; i++){
        data[i] = i;
    }
    for (int i=0; i<10000; i++){
        delay();
        int bytes_writen = 0;
        for (u_int8_t * to_send = data; to_send < data + 256; to_send += bytes_writen){
            int desired_send = data + 256 - to_send;
            bytes_writen = write(fd, to_send, desired_send);
            send_cnt += bytes_writen;
            if (bytes_writen < desired_send){
                tcflush(fd, TCOFLUSH);
            }
        }
    }
    tcflush(fd, TCOFLUSH);
    clock_gettime(CLOCK_MONOTONIC, &end);
    double duration = (end.tv_sec - start.tv_sec);
    duration += (end.tv_nsec - start.tv_nsec) / 1000000000.0;
    printf("took %fs\n", duration);
    printf("written %d bytes\n", send_cnt);
    printf("transfer out rate %fMB/s\n", send_cnt / duration / 1000000.0);
    run = 0;
    pthread_exit(0);
}

void *readThread(void *parameters){
    int fd;
    u_int8_t data[256];
    struct timespec start, end;
    u_int32_t recv_cnt = 0;
    u_int32_t error_cnt = 0;
    u_int8_t i_e = 0;
    fd = *((int*)parameters);
    while (run){
        int bytes_read = 1;
        while (bytes_read > 0 && run){
            bytes_read = read(fd, data, 256);
            if (recv_cnt == 0 && bytes_read > 0){
                clock_gettime(CLOCK_MONOTONIC, &start);
            }
            for (int j=0; j < bytes_read; j++){
                if (data[j] != i_e) {
                    error_cnt += 1;
                    //printf("error byte 0x%02x should be 0x%02x\n", data[j], i_e);
                    i_e = data[j];
                }
                i_e ++;
            }
            recv_cnt += bytes_read;
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double duration = (end.tv_sec - start.tv_sec);
    duration += (end.tv_nsec - start.tv_nsec) / 1000000000.0;
    printf("data loss %.2f%% error %.2f%%\n", 100.0 - 100.0 * ((double) recv_cnt) / send_cnt, 100.0 * error_cnt / send_cnt);
    printf("received error count %d\n", error_cnt);
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
    
    delay();
    tcflush(fd, TCIFLUSH);
    delay();

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
