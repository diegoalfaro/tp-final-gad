#ifndef COLORS_H
#define COLORS_H

// Metric color space constants
#define RGB 1
#define CIELAB 2
#define HSV 3

typedef struct Point
{
    float x, y, z;
} Point;

typedef struct XyzColor
{
    float x, y, z;
} XyzColor;

typedef struct RgbColor
{
    float r, g, b;
} RgbColor;

typedef struct CieLabColor
{
    float l, a, b;
} CieLabColor;

typedef struct HsvColor
{
    float h, s, v;
} HsvColor;

XyzColor rgb2xyz(RgbColor rgbColor);
CieLabColor xyz2lab(XyzColor xyzColor);
CieLabColor rgb2lab(RgbColor rgbColor);
RgbColor lab2rgb(CieLabColor cielabColor);
HsvColor rgb2hsv(RgbColor rgbColor);
RgbColor hsv2rgb(HsvColor hsvColor);
Point hsv2point(HsvColor color);

float euclidean_distance(Point pointA, Point pointB);
float rgb_distance(RgbColor colorA, RgbColor colorB);
float lab_distance(CieLabColor colorA, CieLabColor colorB);
float hsv_distance(HsvColor colorA, HsvColor colorB);

#endif /* COLORS_H */
