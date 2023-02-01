#include "postgres.h"

#include "c.h"
#include "fmgr.h"
#include "imagecomparer.h"
#include "colors.h"
#include "lib/stringinfo.h"
#include "utils/builtins.h"

#include <gd.h>
#include <stdio.h>
#include <math.h>

PG_MODULE_MAGIC;

Datum image2pattern(PG_FUNCTION_ARGS)
{
	gdImagePtr im, tb;
	Pattern *pattern;
	PatternData source;

	Color color;

	bytea *img = PG_GETARG_BYTEA_P(0);
	void *data = VARDATA_ANY(img);
	int size = VARSIZE_ANY_EXHDR(img);
	int i, j;

	im = createImagePtr(size, data);

	PG_FREE_IF_COPY(img, 0);

	tb = gdImageCreateTrueColor(PATTERN_SIZE, PATTERN_SIZE);

	if (!im || !tb)
	{
		elog(NOTICE, "Error creating pattern");
		PG_RETURN_NULL();
	}

	gdImageCopyResampled(tb, im, 0, 0, 0, 0, PATTERN_SIZE, PATTERN_SIZE, im->sx, im->sy);

#if PATTERN_BLURRED
	gdImageGaussianBlur(tb);
#endif

	for (i = 0; i < PATTERN_SIZE; i++)
	{
		for (j = 0; j < PATTERN_SIZE; j++)
		{
			color = getColorFromImagePixel(tb, i, j);
#if USE_PALETTE
			(&source)->values[i][j] = getPaletteColor(color);
#else
			(&source)->values[i][j] = color;
#endif
		}
	}

	gdImageDestroy(tb);

	pattern = (Pattern *)palloc(sizeof(Pattern));
	SET_VARSIZE(pattern, sizeof(Pattern));

	pattern->data = source;

	if (pattern)
	{
		PG_RETURN_BYTEA_P(pattern);
	}
	else
	{
		PG_RETURN_NULL();
	}
}

Datum pattern2image(PG_FUNCTION_ARGS)
{
	bytea *patternData = PG_GETARG_BYTEA_P(0);
	PatternData *pattern = (PatternData *)VARDATA_ANY(patternData);

	int i, j, pixel;
	gdImagePtr tb = gdImageCreate(PATTERN_SIZE, PATTERN_SIZE);
	void *data, *out;
	int size;
	int *pimgSize = &size;
	RgbColor rgbColor;

	for (j = 0; j < PATTERN_SIZE; j++)
	{
		for (i = 0; i < PATTERN_SIZE; i++)
		{
			rgbColor = toRgbColor(pattern->values[i][j]);
			pixel = gdImageColorResolve(tb, rgbColor.r, rgbColor.g, rgbColor.b);
			gdImageSetPixel(tb, i, j, pixel);
		}
	}

	data = gdImageJpegPtr(tb, pimgSize, EXPORT_QUALITY);

	out = (void *)palloc(size + VARHDRSZ);
	SET_VARSIZE(out, size + VARHDRSZ);
	memcpy(VARDATA(out), data, size + VARHDRSZ);

	gdImageDestroy(tb);
	gdFree(data);

	if (data)
	{
		PG_RETURN_BYTEA_P(out);
	}
	else
	{
		PG_RETURN_NULL();
	}
}

Datum pattern_in(PG_FUNCTION_ARGS)
{
	char *source = PG_GETARG_CSTRING(0);
	Pattern *pattern = (Pattern *)palloc(sizeof(Pattern));
	char *s;
	int i, j;

	SET_VARSIZE(pattern, sizeof(Pattern));
	s = source;

	for (i = 0; i < PATTERN_SIZE; i++)
	{
		for (j = 0; j < PATTERN_SIZE; j++)
		{
			pattern->data.values[i][j] = (Color){(float)readFloat(&s, source), (float)readFloat(&s, source), (float)readFloat(&s, source)};
		}
	}

	PG_RETURN_POINTER(pattern);
}

Datum pattern_out(PG_FUNCTION_ARGS)
{
	bytea *patternData = PG_GETARG_BYTEA_P(0);
	PatternData *pattern = (PatternData *)VARDATA_ANY(patternData);
	StringInfoData buf;
	int i, j;

	initStringInfo(&buf);

	appendStringInfoChar(&buf, '[');

	for (i = 0; i < PATTERN_SIZE; i++)
	{
		if (i > 0)
		{
			appendStringInfo(&buf, ", ");
		}

		appendStringInfoChar(&buf, '[');

		for (j = 0; j < PATTERN_SIZE; j++)
		{
			if (j > 0)
			{
				appendStringInfo(&buf, ", ");
			}

			appendStringInfo(&buf, "[%f, %f, %f]", (float)firstColorComponent(pattern->values[i][j]), (float)secondColorComponent(pattern->values[i][j]), (float)thirdColorComponent(pattern->values[i][j]));
		}

		appendStringInfoChar(&buf, ']');
	}

	appendStringInfoChar(&buf, ']');

	PG_FREE_IF_COPY(patternData, 0);
	PG_RETURN_CSTRING(buf.data);
}

Datum pattern_distance(PG_FUNCTION_ARGS)
{
	bytea *patternDataA = PG_GETARG_BYTEA_P(0);
	PatternData *patternA = (PatternData *)VARDATA_ANY(patternDataA);

	bytea *patternDataB = PG_GETARG_BYTEA_P(1);
	PatternData *patternB = (PatternData *)VARDATA_ANY(patternDataB);

	float distance = patternDistance(patternA, patternB);

	PG_RETURN_FLOAT4(distance);
}

Datum max_pattern_distance(PG_FUNCTION_ARGS)
{
	PG_RETURN_FLOAT4(MAX_PATTERN_DISTANCE);
}

static gdImagePtr createImagePtr(int size, void *data)
{
	gdImagePtr im;

	if ((im = gdImageCreateFromJpegPtr(size, data)))
	{
		return im;
	}
	else if ((im = gdImageCreateFromPngPtr(size, data)))
	{
		return im;
	}
	else if ((im = gdImageCreateFromGifPtr(size, data)))
	{
		return im;
	}
	else if ((im = gdImageCreateFromWBMPPtr(size, data)))
	{
		return im;
	}

	return NULL;
}

static Color getColorFromImagePixel(gdImagePtr img, int i, int j)
{
	int pixel = gdImageGetTrueColorPixel(img, i, j);
	RgbColor color = {
		.r = gdTrueColorGetRed(pixel),
		.g = gdTrueColorGetGreen(pixel),
		.b = gdTrueColorGetBlue(pixel)};
	return fromRgbColor(color);
}

static float readFloat(char **s, char *orig_string)
{
	char c, *start;
	float result;

	while (true)
	{
		c = **s;
		switch (c)
		{
		case ' ':
		case '[':
		case ']':
		case ',':
			(*s)++;
			continue;
		case '\0':
			ereport(ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION), errmsg("invalid input syntax for image pattern")));
		default:
			break;
		}
		break;
	}

	start = *s;
	result = strtof(start, s);

	if (start == *s)
	{
		ereport(ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION), errmsg("invalid input syntax for image pattern")));
	}

	return result;
}

static float colorDistance(Color colorA, Color colorB)
{
	return distance(colorA, colorB);
}

static float patternDistance(PatternData *patternA, PatternData *patternB)
{
	int i, j;
	float distance = 0.0f;

	for (i = 0; i < PATTERN_SIZE; i++)
	{
		for (j = 0; j < PATTERN_SIZE; j++)
		{
			distance += colorDistance(patternA->values[i][j], patternB->values[i][j]);
		}
	}

	return distance;
}

#if USE_PALETTE
static Color getPaletteColor(Color color)
{
	const RgbColor palette[PALETTE_SIZE] = {PALETTE_COLORS};

	float minDistance, currentDistance;
	Color closestColor;
	int i;

	minDistance = MAX_PATTERN_DISTANCE;

	for (i = 0; i < PALETTE_SIZE; i++)
	{
		currentDistance = colorDistance(color, fromRgbColor(palette[i]));
		if (currentDistance < minDistance)
		{
			minDistance = currentDistance;
			closestColor = fromRgbColor(palette[i]);
		}
	}

	return closestColor;
}
#endif