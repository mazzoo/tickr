/* jpegsize
 * prints the image size of the jpeg from stdin or argv[1]
 * "X Y float_megapixels"
 * e.g.
 * 4440 3179 14.115
 *
 * GPL v2
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <jpeglib.h>
#include <jerror.h>

void jerr_emit_message(j_common_ptr cinfo, int msg_level) {}
void jerr_output_message(j_common_ptr cinfo) {}

int opt_x = 0;
int opt_y = 0;
int opt_m = 0;

int main(int argc, char ** argv)
{
	FILE * f;

	if (argc == 1)
		f = stdin;
	else
	{
		char * fn;
		if (argv[1][0] == '-')
		{
			fn = argv[2];
			switch (argv[1][1])
			{
				case 'x':
					opt_x = 1;
					break;
				case 'y':
					opt_y = 1;
					break;
				case 'm':
					opt_m = 1;
					break;
				default:
					exit(1);
			}
		}else{
			fn = argv[1];
		}
		f = fopen(fn, "rb");
		if (!f)
			exit(1);
	}

	struct jpeg_decompress_struct cinfo;
	struct jpeg_error_mgr jerr;
	cinfo.err = jpeg_std_error(&jerr);
	cinfo.err->emit_message   = jerr_emit_message;
	cinfo.err->output_message = jerr_output_message;
	jpeg_create_decompress(&cinfo);
	if (cinfo.err->msg_code == JERR_INPUT_EMPTY)
		exit(1);
	jpeg_stdio_src(&cinfo, f);
	if (JPEG_HEADER_OK != jpeg_read_header(&cinfo, TRUE))
		exit(1);
	if (opt_x | opt_y | opt_m)
	{
		if (opt_x)
			printf("%4.d\n", cinfo.image_width);
		if (opt_y)
			printf("%4.d\n", cinfo.image_height);
		if (opt_m)
			printf("%2.3f\n",
				cinfo.image_width * cinfo.image_height / 1000000.0);

	}else{
		printf("%4.d %4.d %2.3f\n",
			cinfo.image_width,
			cinfo.image_height,
			cinfo.image_width * cinfo.image_height / 1000000.0
		      );
	}
	return 0;
}

