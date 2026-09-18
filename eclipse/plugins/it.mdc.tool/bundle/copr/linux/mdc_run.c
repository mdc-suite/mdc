/* SPDX-License-Identifier: MIT */
/* Generic one-output network runner. Input files contain little-endian u32
 * transport words (one token per word); no image parsing or role inference. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include "mdc_user.h"
#include "mdc_config.h"
static int parse(const char *s, uint32_t *v)
{
    char *end; unsigned long n;
    errno=0; n=strtoul(s,&end,0);
    if (errno || !*s || *end || n>UINT32_MAX) return -1;
    *v=(uint32_t)n; return 0;
}
int main(int argc,char **argv)
{
    void *input[MDC_CHANNELS]={0}, *out=NULL;
    uint32_t lengths[MDC_CHANNELS]={0}, mode, beats, actual=0;
    unsigned int i, rx=0, ninput=0, arg=3, modes=MDC_MODES;
    struct mdc_info info={0};
    struct mdc_transfer status;
    int fd=-1, rc=1;
    FILE *f=NULL;
    for(i=0;i<MDC_CHANNELS;i++) { if(mdc_directions[i])ninput++;else rx=i; }
    if(MDC_OUTPUTS!=1 || argc!=(int)ninput+4 || parse(argv[1],&mode) || parse(argv[2],&beats) ||
        !beats || beats>MDC_BUFFER_BYTES/4 || mode>255) {
        fprintf(stderr,"Usage: %s MODE OUTPUT_BEATS INPUT0.bin [INPUT1.bin ...] OUTPUT.bin\nOne-output networks only; files use 32-bit little-endian transport words.\n",argv[0]);return 2;
    }
    for(i=0;i<modes;i++) if(mdc_modes[i]==mode)break;
    if(i==modes) { fprintf(stderr,"Unknown generated mode ID\n");return 2; }
    for(i=0;i<MDC_CHANNELS;i++) {
        size_t n;
        if(!mdc_directions[i])continue;
        f=fopen(argv[arg++],"rb");if(!f) {perror("input");goto done;}
        input[i]=malloc(MDC_BUFFER_BYTES+1);if(!input[i])goto done;
        n=fread(input[i],1,MDC_BUFFER_BYTES+1,f);
        if(ferror(f)||!n||n>MDC_BUFFER_BYTES||n%4) {fprintf(stderr,"Invalid input size\n");goto done;}
        fclose(f);f=NULL;lengths[i]=(uint32_t)n;
    }
    out=malloc(beats*4);if(!out)goto done;
    fd=open("/dev/mdc_accel0",O_RDWR);if(fd<0){perror("open");goto done;}
    if(ioctl(fd,MDC_GET_INFO,&info)||info.abi!=MDC_ABI_VERSION||info.channels!=MDC_CHANNELS||info.output_ports!=1) {fprintf(stderr,"Driver ABI/shape mismatch\n");goto done;}
    if(ioctl(fd,MDC_RESET_ALL)||mdc_reg_write(fd,0,(mode<<24)|4)||
       mdc_reg_write(fd,4,beats)||mdc_reg_write(fd,0,(mode<<24)|1)) {perror("configure");goto done;}
    /* Arm receiver first; queue every transmitter before waiting. */
    if(mdc_submit(fd,rx,NULL,beats*4)) {perror("submit RX");goto done;}
    for(i=0;i<MDC_CHANNELS;i++)
        if(mdc_directions[i] && mdc_submit(fd,i,input[i],lengths[i])) {perror("submit TX");goto done;}
    for(i=0;i<MDC_CHANNELS;i++) {
        if(mdc_wait(fd,i,10000,&status)) {fprintf(stderr,"channel %u status=0x%08x: ",i,status.status);perror("wait");goto done;}
    }
    if(mdc_fetch(fd,rx,out,beats*4,&actual)) {perror("fetch");goto done;}
    if(actual!=beats*4) {fprintf(stderr,"Unexpected output bytes: %u\n",actual);goto done;}
    f=fopen(argv[argc-1],"wb");if(!f){perror("output");goto done;}
    if(fwrite(out,1,actual,f)!=actual){perror("write");goto done;}
    if(fclose(f)){f=NULL;perror("close output");goto done;}f=NULL;
    printf("Completed mode %u: %u output bytes\n",mode,actual);rc=0;
done:
    if(f)fclose(f);
    if(fd>=0)close(fd);
    for(i=0;i<MDC_CHANNELS;i++)free(input[i]);
    free(out);return rc;
}
