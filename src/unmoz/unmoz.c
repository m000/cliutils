#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include "lz4.h"

#if __MINGW32__
#define __MSVCRT_VERSION__ 0x0601
#endif

#define MOZLZ4_MAGIC "mozLz40"

uint64_t fsize(const char *filename)
{
#if __MINGW32__
	struct __stat64 st;
	if (_stat64(filename, &st) == 0) return st.st_size;
#else
	struct stat st;
	if (stat(filename, &st) == 0) return st.st_size;
#endif
	return 0;
}

int main (int argc, char *argv[])
{
	FILE *in;
	uint8_t *input;
	uint32_t isize = 0;
	uint32_t ipos = 0;

	FILE *out;
	uint32_t osize = 0;
	uint8_t *output;

	int32_t decompressed;
	uint32_t n;

	if (argc != 3) {
		fprintf(stderr,	"Mozilla LZ4 4a version decompressor.\n"
						"Usage: unmoz inputfile outputfile\n"
		);
		return 1;
	}

	in = fopen(argv[1], "rb");
	if (!in) { perror("Error opening input file"); return 1; }

	isize = fsize(argv[1]);
	if (isize < 12 || isize > 134217728) {
		fprintf(stderr, "Size is %" PRIu32 " bytes, must be >12 bytes and <128MB\n", isize);
		return 1;
	}

	input = malloc(isize * sizeof(uint8_t));
	if (input == NULL) { perror("Cannot allocate memory"); return 1; }
	memset(input, 0, isize*sizeof(uint8_t));

	n = fread(input, sizeof(uint8_t), isize, in);
	if (n != isize) {
		fprintf(stderr, "Only got %" PRIu32 " input bytes. Quitting.\n", n);
		perror("Read error");
		return 1;
	}

	/* check magic number */
	if (strncmp((char *)(input+ipos), MOZLZ4_MAGIC, strlen(MOZLZ4_MAGIC)+1) != 0) {
		fprintf(stderr,	"Magic number mismatch.\n"
						"Expected:\n\t"
		);
		for (int i=0; i<strlen(MOZLZ4_MAGIC)+1; i++) { fprintf(stderr, "%4c", MOZLZ4_MAGIC[i]); }
		fprintf(stderr, "\n\t");
		for (int i=0; i<strlen(MOZLZ4_MAGIC)+1; i++) { fprintf(stderr, "%4u", MOZLZ4_MAGIC[i]); }
		fprintf(stderr, "\nGot:\n\t");
		for (int i=0; i<strlen(MOZLZ4_MAGIC)+1; i++) { fprintf(stderr, "%4c", input[i+ipos]); }
		fprintf(stderr, "\n\t");
		for (int i=0; i<strlen(MOZLZ4_MAGIC)+1; i++) { fprintf(stderr, "%4u", input[i+ipos]); }
		fprintf(stderr, "\n");
		return 1;
	}
	printf("Magic number ok!\n");
	ipos += strlen(MOZLZ4_MAGIC)+1;

	/* read output size - big endian */
	osize = input[ipos] + (input[ipos + 1] << 8) + (input[ipos + 2] << 16) + (input[ipos + 3] << 24);
	printf("Output size: %" PRIu32 "\n", osize);
	ipos += sizeof(uint32_t);

	output = malloc(osize * sizeof(uint8_t));
	if (input == NULL) { perror("Cannot allocate memory"); return 1; }
	memset(output, 0, osize*sizeof(uint8_t));

	/* decompress */
	decompressed = LZ4_decompress_fast((char *)(input+ipos), (char *)output, osize);
	if (decompressed < 0) {
		perror("Decompression problem");
		return 1;
	}
	printf("Decompressed %" PRIu32 "/%" PRIu32 " input bytes.\n", decompressed, isize-ipos);

	/* write */
	out = fopen(argv[2], "wb");
	if (!out) { perror("Error opening output file"); return 1; }
	n = fwrite(output, sizeof(uint8_t), osize, out);
	if (n != osize) {
		fprintf(stderr, "Wrote %" PRIu32 "/%" PRIu32 " output bytes.\n", n, osize);
		perror("Cannot write output file");
		return 1;
	}

	fclose(in);
	fclose(out);
	printf("Done.\n");
	return 0;
}

/* vim: set tabstop=4 softtabstop=4 noexpandtab: */
