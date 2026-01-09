#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define MAXLINE 4096

static void err_sys(const char *msg) {
    perror(msg);
    exit(1);
}

static void err_quit(const char *msg) {
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

int main(int argc, char **argv) {
    int sockfd;
    ssize_t n;
    char recvline[MAXLINE + 1];
    struct sockaddr_in servaddr;

    if (argc != 2) {
        err_quit("usage: ./daytimetcpcli <IPaddresss>");
    }

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        err_sys("socket error");
    }

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    
    // daytime server (RFC 867) -> port 13 (default not available) -> local testing port 1313
    // To test: run server:  nc -l 1313
    //    AND TYPE SOMETHING

    servaddr.sin_port = htons(1313);
    
    if (inet_pton(AF_INET, argv[1], &servaddr.sin_addr) <= 0) {
        fprintf(stderr, "inet_pton error for %s\n", argv[1]);
        exit(1);
    }

    if (connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0) {
        err_sys("connect error");
    }

    while ((n = read(sockfd, recvline, MAXLINE)) > 0) {
        recvline[n] = 0; /* null terminate */

        /*
         * IO Buffering Note:
         * fputs() is part of the Standard I/O library and is buffered.
         * If the output does not contain a newline, it might not print immediately
         * unless we call fflush(stdout).
         *
         * Alternatively, write(STDOUT_FILENO, ...) is a system call and is unbuffered.
         */
        if (fputs(recvline, stdout) == EOF) {
            err_sys("fputs error");
        }
    }

    if (n < 0) {
        err_sys("read error");
    }

    close(sockfd);
    return 0;

}
