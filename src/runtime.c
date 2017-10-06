#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>


/* a simple driver for scheme_entry */
extern intptr_t scheme_entry(void);

int main(int argc, char** argv){
   printf("%" PRIdPTR "\n", scheme_entry());
   return 0;
}
