// gcc pls.c -o pls
// sudo chmod u+s pls
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
    int i;
    int ret;
    char command[1024] = "";

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command>\n", argv[0]);
        return 1;
    }

    for (i = 1; i < argc; i++) {
        strcat(command, argv[i]);
        if (i < argc - 1) {
            strcat(command, " ");
        }
    }

    ret = system(command);

    return WEXITSTATUS(ret);
}
