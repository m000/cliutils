#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include "lz4.h"

/*
   gcc -c lz4.c
   gcc -c unmoz.c
   gcc -o unmoz.exe lz4.o unmoz.o
*/

#if __MINGW32__
#define __MSVCRT_VERSION__ 0x0601
#endif

long long int bytesin  = 0;
long long int bytesout = 0;
FILE *my_in, *my_out;
unsigned char * bufin;
char * bufout;

long long int fsize(const char *filename)
{

#if __MINGW32__
	struct __stat64 st;
	if (_stat64(filename, &st) == 0) return st.st_size;
#else
	struct stat st;
	if (stat(filename, &st) == 0) return st.st_size;
#endif

	return -1;
}

int main (int argc, char *argv[])
{
	FILE *in, *out;
	int i, ibytes, igotbytes, outbytes, donebytes, putbytes;

	if (argc != 3) {
		fprintf(stderr, "\n Mozilla LZ4 4a version decompressor\n"
		        "\n Usage : unmoz inputfile outputfile"
		        "\n %d\n", argc);
		return 0;
	}

	in = fopen(argv[1], "rb");
	if (!in) {
		perror("\n Error opening input file");
		return 0;
	}

	bytesin = fsize(argv[1]);
	if (bytesin < 12 || bytesin > 134217728) {
		fprintf(stderr, "\n Size is %I64d, must be >12 bytes and <128MB\n", bytesin);
		perror("\n Input file size problem");
		return 0;
	}
	ibytes = bytesin;

	my_in = in;

	out = fopen(argv[2], "wb");
	if (!out) {
		perror("\n Error opening output file");
		return 0;
	}

	my_out = out;

	/* main code here */

	bufin = malloc(ibytes);
	if (bufin == NULL) {
		perror("\n Cannot malloc ibytes");
		return 0;
	}
	memset(bufin,0,ibytes);

	igotbytes = fread(bufin, 1, ibytes, in);

	if (igotbytes != ibytes) {
		fprintf(stderr, "\n Only got %d\n input bytes. Quitting.\n", igotbytes);
		perror("\n Short input file. Stop.\n");
		return 0;
	}

	for (i=0; i<8; i++) {             /* mozLz40\0 */
		printf("%c\n", bufin[i]);      /* 109, 111, 122, 76, 122, 52, 48, 0 */
	}

	if ( bufin[0] != 109 ||
	     bufin[1] != 111 ||
	     bufin[2] != 122 ||
	     bufin[3] != 76  ||
	     bufin[4] != 122 ||
	     bufin[5] != 52  ||
	     bufin[6] != 48  ||
	     bufin[7] != 0 ) {

		perror("\n Version magic does not match mozLz40\n");
		return 0;
	}

	bufin += 8; /* move past magic header, next do size */

	for (i=0; i<4; i++) {             /* size */
		printf("%d\n", bufin[i]);      /* backwards */
	}

	outbytes = bufin[0] + ( bufin[1] << 8) + ( bufin[2] << 16) + (bufin[3] << 24);

	bufin += 4; /* Move past 32 bit size field */

	ibytes -= 12; /* correct the remaining buffer size, before decompress */

	printf("\nOutbytes = %d\n", outbytes);

	bufout = malloc(outbytes);
	if (bufout == NULL) {
		perror("\n Cannot malloc outbytes\n");
		return 0;
	}
	memset(bufout,0,outbytes);

	if ((donebytes = LZ4_decompress_fast (bufin, bufout, outbytes)) != ibytes) {
		fprintf(stderr, "\n LZ4_decompress_fast returns %d\n Quitting.\n", donebytes);
		perror("\n Decompression problem\n");
		return 0;
	}

	putbytes = fwrite(bufout, 1, outbytes, out);

	if (putbytes != outbytes) {
		fprintf(stderr, "\n outbytes %d putbytes %d\n Quitting.\n", outbytes, putbytes);
		perror("\n Decompress done but cannot write correctly\n");
		return 0;
	}

	printf("\nReached the end\n");

	if (in ) fclose(in);
	if (out) fclose(out);
	return 0;
}
