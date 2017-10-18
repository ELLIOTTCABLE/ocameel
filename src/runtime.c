#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>


/* a simple driver for scheme_entry */
extern int32_t scheme_entry(void);

int main(int argc, char** argv){
   printf("%" PRId32"\n", scheme_entry());
   return 0;
}
