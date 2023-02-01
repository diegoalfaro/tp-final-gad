#include "postgres.h"

#include <stdio.h>
#include <math.h>

#include "colors.h"

#define MAX(a, b) ((a) > (b) ? a : b)
#define MIN(a, b) ((a) < (b) ? a : b)

XyzColor rgb2xyz(RgbColor rgbColor)
{
	float r, g, b;
	XyzColor xyzColor;

	r = rgbColor.r / 255.0;
	g = rgbColor.g / 255.0;
	b = rgbColor.b / 255.0;

	if (r > 0.04045)
		r = powf(((r + 0.055) / 1.055), 2.4);
	else
		r /= 12.92;

	if (g > 0.04045)
		g = powf(((g + 0.055) / 1.055), 2.4);
	else
		g /= 12.92;

	if (b > 0.04045)
		b = powf(((b + 0.055) / 1.055), 2.4);
	else
		b /= 12.92;

	r *= 100;
	g *= 100;
	b *= 100;

	// Calibration for observer @2° with illumination = D65
	xyzColor.x = r * 0.4124 + g * 0.3576 + b * 0.1805;
	xyzColor.y = r * 0.2126 + g * 0.7152 + b * 0.0722;
	xyzColor.z = r * 0.0193 + g * 0.1192 + b * 0.9505;

	return xyzColor;
}

CieLabColor xyz2lab(XyzColor xyzColor)
{
	float x, y, z;
	const float refX = 95.047, refY = 100.0, refZ = 108.883;
	CieLabColor cielabColor;

	// References set at calibration for observer @2° with illumination = D65
	x = xyzColor.x / refX;
	y = xyzColor.y / refY;
	z = xyzColor.z / refZ;

	if (x > 0.008856)
		x = powf(x, 1 / 3.0);
	else
		x = (7.787 * x) + (16.0 / 116.0);

	if (y > 0.008856)
		y = powf(y, 1 / 3.0);
	else
		y = (7.787 * y) + (16.0 / 116.0);

	if (z > 0.008856)
		z = powf(z, 1 / 3.0);
	else
		z = (7.787 * z) + (16.0 / 116.0);

	cielabColor.l = 116 * y - 16;
	cielabColor.a = 500 * (x - y);
	cielabColor.b = 200 * (y - z);

	return cielabColor;
}

CieLabColor rgb2lab(RgbColor rgbColor)
{
	return xyz2lab(rgb2xyz(rgbColor));
}

RgbColor lab2rgb(CieLabColor cieLabColor)
{
	float y = (cieLabColor.l + 16) / 116,
		  x = cieLabColor.a / 500 + y,
		  z = y - cieLabColor.b / 200,
		  r, g, b;

	RgbColor rgbColor;

	x = 0.95047 * ((x * x * x > 0.008856) ? x * x * x : (x - 16 / 116) / 7.787);
	y = 1.00000 * ((y * y * y > 0.008856) ? y * y * y : (y - 16 / 116) / 7.787);
	z = 1.08883 * ((z * z * z > 0.008856) ? z * z * z : (z - 16 / 116) / 7.787);

	r = x * 3.2406 + y * -1.5372 + z * -0.4986;
	g = x * -0.9689 + y * 1.8758 + z * 0.0415;
	b = x * 0.0557 + y * -0.2040 + z * 1.0570;

	r = (r > 0.0031308) ? (1.055 * pow(r, 1 / 2.4) - 0.055) : 12.92 * r;
	g = (g > 0.0031308) ? (1.055 * pow(g, 1 / 2.4) - 0.055) : 12.92 * g;
	b = (b > 0.0031308) ? (1.055 * pow(b, 1 / 2.4) - 0.055) : 12.92 * b;

	rgbColor.r = MAX(0, MIN(1, r)) * 255;
	rgbColor.g = MAX(0, MIN(1, g)) * 255;
	rgbColor.b = MAX(0, MIN(1, b)) * 255;

	elog(NOTICE, "cieLabColor: (%f, %f, %f)", cieLabColor.l, cieLabColor.a, cieLabColor.b);
	elog(NOTICE, "rgbColor: (%f, %f, %f)", rgbColor.r, rgbColor.g, rgbColor.b);

	return rgbColor;
}

RgbColor hsv2rgb(HsvColor hsvColor)
{
	double hh, p, q, t, ff;
	long i;
	RgbColor rgbColor;

	if (hsvColor.s <= 0.0)
	{
		rgbColor.r = hsvColor.v;
		rgbColor.g = hsvColor.v;
		rgbColor.b = hsvColor.v;
		return rgbColor;
	}
	hh = hsvColor.h;
	if (hh >= 360.0)
		hh = 0.0;
	hh /= 60.0;
	i = (long)hh;
	ff = hh - i;
	p = hsvColor.v * (1.0 - hsvColor.s);
	q = hsvColor.v * (1.0 - (hsvColor.s * ff));
	t = hsvColor.v * (1.0 - (hsvColor.s * (1.0 - ff)));

	switch (i)
	{
	case 0:
		rgbColor.r = hsvColor.v;
		rgbColor.g = t;
		rgbColor.b = p;
		break;
	case 1:
		rgbColor.r = q;
		rgbColor.g = hsvColor.v;
		rgbColor.b = p;
		break;
	case 2:
		rgbColor.r = p;
		rgbColor.g = hsvColor.v;
		rgbColor.b = t;
		break;

	case 3:
		rgbColor.r = p;
		rgbColor.g = q;
		rgbColor.b = hsvColor.v;
		break;
	case 4:
		rgbColor.r = t;
		rgbColor.g = p;
		rgbColor.b = hsvColor.v;
		break;
	case 5:
	default:
		rgbColor.r = hsvColor.v;
		rgbColor.g = p;
		rgbColor.b = q;
		break;
	}

	return rgbColor;
}

HsvColor rgb2hsv(RgbColor rgbColor)
{
	double min, max, delta;
	HsvColor hsvColor;

	min = rgbColor.r < rgbColor.g ? rgbColor.r : rgbColor.g;
	min = min < rgbColor.b ? min : rgbColor.b;

	max = rgbColor.r > rgbColor.g ? rgbColor.r : rgbColor.g;
	max = max > rgbColor.b ? max : rgbColor.b;

	hsvColor.v = max;
	delta = max - min;
	if (delta < 0.00001)
	{
		hsvColor.s = 0;
		hsvColor.h = 0;
		return hsvColor;
	}
	if (max > 0.0)
	{
		hsvColor.s = (delta / max);
	}
	else
	{
		hsvColor.s = 0.0;
		hsvColor.h = NAN;
		return hsvColor;
	}
	if (rgbColor.r >= max)
		hsvColor.h = (rgbColor.g - rgbColor.b) / delta;
	else if (rgbColor.g >= max)
		hsvColor.h = 2.0 + (rgbColor.b - rgbColor.r) / delta;
	else
		hsvColor.h = 4.0 + (rgbColor.r - rgbColor.g) / delta;

	hsvColor.h *= 60.0;

	if (hsvColor.h < 0.0)
		hsvColor.h += 360.0;

	return hsvColor;
}

float euclidean_distance(Point pointA, Point pointB)
{
	return sqrt(pow((pointA.x - pointB.x), 2) + pow((pointA.y - pointB.y), 2) + pow((pointA.z - pointB.z), 2));
}

float rgb_distance(RgbColor colorA, RgbColor colorB)
{
	Point pointA = {.x = colorA.r, .y = colorA.g, .z = colorA.b},
		  pointB = {.x = colorB.r, .y = colorB.g, .z = colorB.b};

	return euclidean_distance(pointA, pointB);
}

float lab_distance(CieLabColor colorA, CieLabColor colorB)
{
	Point pointA = {.x = colorA.l, .y = colorA.a, .z = colorA.b},
		  pointB = {.x = colorB.l, .y = colorB.a, .z = colorB.b};

	return euclidean_distance(pointA, pointB);
}

float hsv_distance(HsvColor colorA, HsvColor colorB)
{
	Point pointA = hsv2point(colorA),
		  pointB = hsv2point(colorB);

	return euclidean_distance(pointA, pointB);
}

Point hsv2point(HsvColor color)
{
	Point point = {
		.x = color.s * cos(color.h),
		.y = color.s * sin(color.h),
		.z = color.v};

	return point;
}
