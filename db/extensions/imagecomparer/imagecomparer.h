#ifndef IMAGECOMPARER_H
#define IMAGECOMPARER_H

#include "postgres.h"
#include "colors.h"
#include <gd.h>

// Metric color space constants
#define METRIC_COLOR_SPACE CIELAB

// Pattern constants
#define PATTERN_SIZE 12
#define PATTERN_BLURRED 0

// Palette constants
#define USE_PALETTE 0
#define PALETTE_SIZE 147
#define PALETTE_COLORS ALICEBLUE, ANTIQUEWHITE, AQUA, AQUAMARINE, AZURE, BEIGE, BISQUE, BLACK, BLANCHEDALMOND, BLUE, BLUEVIOLET, BROWN, BURLYWOOD, CADETBLUE, CHARTREUSE, CHOCOLATE, CORAL, CORNFLOWERBLUE, CORNSILK, CRIMSON, CYAN, DARKBLUE, DARKCYAN, DARKGOLDENROD, DARKGRAY, DARKGREEN, DARKGREY, DARKKHAKI, DARKMAGENTA, DARKOLIVEGREEN, DARKORANGE, DARKORCHID, DARKRED, DARKSALMON, DARKSEAGREEN, DARKSLATEBLUE, DARKSLATEGRAY, DARKSLATEGREY, DARKTURQUOISE, DARKVIOLET, DEEPPINK, DEEPSKYBLUE, DIMGRAY, DIMGREY, DODGERBLUE, FIREBRICK, FLORALWHITE, FORESTGREEN, FUCHSIA, GAINSBORO, GHOSTWHITE, GOLD, GOLDENROD, GRAY, GREEN, GREENYELLOW, GREY, HONEYDEW, HOTPINK, INDIANRED, INDIGO, IVORY, KHAKI, LAVENDER, LAVENDERBLUSH, LAWNGREEN, LEMONCHIFFON, LIGHTBLUE, LIGHTCORAL, LIGHTCYAN, LIGHTGOLDENRODYELLOW, LIGHTGRAY, LIGHTGREEN, LIGHTGREY, LIGHTPINK, LIGHTSALMON, LIGHTSEAGREEN, LIGHTSKYBLUE, LIGHTSLATEGRAY, LIGHTSLATEGREY, LIGHTSTEELBLUE, LIGHTYELLOW, LIME, LIMEGREEN, LINEN, MAGENTA, MAROON, MEDIUMAQUAMARINE, MEDIUMBLUE, MEDIUMORCHID, MEDIUMPURPLE, MEDIUMSEAGREEN, MEDIUMSLATEBLUE, MEDIUMSPRINGGREEN, MEDIUMTURQUOISE, MEDIUMVIOLETRED, MIDNIGHTBLUE, MINTCREAM, MISTYROSE, MOCCASIN, NAVAJOWHITE, NAVY, OLDLACE, OLIVE, OLIVEDRAB, ORANGE, ORANGERED, ORCHID, PALEGOLDENROD, PALEGREEN, PALETURQUOISE, PALEVIOLETRED, PAPAYAWHIP, PEACHPUFF, PERU, PINK, PLUM, POWDERBLUE, PURPLE, RED, ROSYBROWN, ROYALBLUE, SADDLEBROWN, SALMON, SANDYBROWN, SEAGREEN, SEASHELL, SIENNA, SILVER, SKYBLUE, SLATEBLUE, SLATEGRAY, SLATEGREY, SNOW, SPRINGGREEN, STEELBLUE, TAN, TEAL, THISTLE, TOMATO, TURQUOISE, VIOLET, WHEAT, WHITE, WHITESMOKE, YELLOW, YELLOWGREEN

// Export image constants
#define EXPORT_QUALITY 100

#if METRIC_COLOR_SPACE == RGB
#define Color RgbColor
#define distance(colorA, colorB) rgb_distance(colorA, colorB)
#define fromRgbColor(color) color
#define toRgbColor(color) color
#define firstColorComponent(color) color.r
#define secondColorComponent(color) color.g
#define thirdColorComponent(color) color.b
#elif METRIC_COLOR_SPACE == CIELAB
#define Color CieLabColor
#define distance(colorA, colorB) lab_distance(colorA, colorB)
#define fromRgbColor(color) rgb2lab(color)
#define toRgbColor(color) lab2rgb(color)
#define firstColorComponent(color) color.l
#define secondColorComponent(color) color.a
#define thirdColorComponent(color) color.b
#elif METRIC_COLOR_SPACE == HSV
#define Color HsvColor
#define distance(colorA, colorB) hsv_distance(colorA, colorB)
#define fromRgbColor(color) rgb2hsv(color)
#define toRgbColor(color) hsv2rgb(color)
#define firstColorComponent(color) color.h
#define secondColorComponent(color) color.s
#define thirdColorComponent(color) color.v
#endif

#define MAX_PATTERN_DISTANCE colorDistance(fromRgbColor(BLACK), fromRgbColor(WHITE)) * PATTERN_SIZE *PATTERN_SIZE

typedef struct
{
	Color values[PATTERN_SIZE][PATTERN_SIZE];
} PatternData;

typedef struct
{
	char vl_len_[4];
	PatternData data;
} Pattern;

PG_FUNCTION_INFO_V1(image2pattern);
Datum image2pattern(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(pattern2image);
Datum pattern2image(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(pattern_in);
Datum pattern_in(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(pattern_out);
Datum pattern_out(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(pattern_distance);
Datum pattern_distance(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(max_pattern_distance);
Datum max_pattern_distance(PG_FUNCTION_ARGS);

static gdImagePtr createImagePtr(int size, void *data);
static Color getColorFromImagePixel(gdImagePtr img, int i, int j);
static float readFloat(char **s, char *orig_string);
static float colorDistance(Color colorA, Color colorB);
static float patternDistance(PatternData *patternA, PatternData *patternB);
#if USE_PALETTE
static Color getPaletteColor(Color color);
#endif

// HTML Colors
const RgbColor ALICEBLUE = {.r = 240, .g = 248, .b = 255};			  // rgb(240, 248, 255)
const RgbColor ANTIQUEWHITE = {.r = 250, .g = 235, .b = 215};		  // rgb(250, 235, 215)
const RgbColor AQUA = {.r = 0, .g = 255, .b = 255};					  // rgb(0, 255, 255)
const RgbColor AQUAMARINE = {.r = 127, .g = 255, .b = 212};			  // rgb(127, 255, 212)
const RgbColor AZURE = {.r = 240, .g = 255, .b = 255};				  // rgb(240, 255, 255)
const RgbColor BEIGE = {.r = 245, .g = 245, .b = 220};				  // rgb(245, 245, 220)
const RgbColor BISQUE = {.r = 255, .g = 228, .b = 196};				  // rgb(255, 228, 196)
const RgbColor BLACK = {.r = 0, .g = 0, .b = 0};					  // rgb(0, 0, 0)
const RgbColor BLANCHEDALMOND = {.r = 255, .g = 235, .b = 205};		  // rgb(255, 235, 205)
const RgbColor BLUE = {.r = 0, .g = 0, .b = 255};					  // rgb(0, 0, 255)
const RgbColor BLUEVIOLET = {.r = 138, .g = 43, .b = 226};			  // rgb(138, 43, 226)
const RgbColor BROWN = {.r = 165, .g = 42, .b = 42};				  // rgb(165, 42, 42)
const RgbColor BURLYWOOD = {.r = 222, .g = 184, .b = 135};			  // rgb(222, 184, 135)
const RgbColor CADETBLUE = {.r = 95, .g = 158, .b = 160};			  // rgb(95, 158, 160)
const RgbColor CHARTREUSE = {.r = 127, .g = 255, .b = 0};			  // rgb(127, 255, 0)
const RgbColor CHOCOLATE = {.r = 210, .g = 105, .b = 30};			  // rgb(210, 105, 30)
const RgbColor CORAL = {.r = 255, .g = 127, .b = 80};				  // rgb(255, 127, 80)
const RgbColor CORNFLOWERBLUE = {.r = 100, .g = 149, .b = 237};		  // rgb(100, 149, 237)
const RgbColor CORNSILK = {.r = 255, .g = 248, .b = 220};			  // rgb(255, 248, 220)
const RgbColor CRIMSON = {.r = 220, .g = 20, .b = 60};				  // rgb(220, 20, 60)
const RgbColor CYAN = {.r = 0, .g = 255, .b = 255};					  // rgb(0, 255, 255)
const RgbColor DARKBLUE = {.r = 0, .g = 0, .b = 139};				  // rgb(0, 0, 139)
const RgbColor DARKCYAN = {.r = 0, .g = 139, .b = 139};				  // rgb(0, 139, 139)
const RgbColor DARKGOLDENROD = {.r = 184, .g = 134, .b = 11};		  // rgb(184, 134, 11)
const RgbColor DARKGRAY = {.r = 169, .g = 169, .b = 169};			  // rgb(169, 169, 169)
const RgbColor DARKGREEN = {.r = 0, .g = 100, .b = 0};				  // rgb(0, 100, 0)
const RgbColor DARKGREY = {.r = 169, .g = 169, .b = 169};			  // rgb(169, 169, 169)
const RgbColor DARKKHAKI = {.r = 189, .g = 183, .b = 107};			  // rgb(189, 183, 107)
const RgbColor DARKMAGENTA = {.r = 139, .g = 0, .b = 139};			  // rgb(139, 0, 139)
const RgbColor DARKOLIVEGREEN = {.r = 85, .g = 107, .b = 47};		  // rgb(85, 107, 47)
const RgbColor DARKORANGE = {.r = 255, .g = 140, .b = 0};			  // rgb(255, 140, 0)
const RgbColor DARKORCHID = {.r = 153, .g = 50, .b = 204};			  // rgb(153, 50, 204)
const RgbColor DARKRED = {.r = 139, .g = 0, .b = 0};				  // rgb(139, 0, 0)
const RgbColor DARKSALMON = {.r = 233, .g = 150, .b = 122};			  // rgb(233, 150, 122)
const RgbColor DARKSEAGREEN = {.r = 143, .g = 188, .b = 143};		  // rgb(143, 188, 143)
const RgbColor DARKSLATEBLUE = {.r = 72, .g = 61, .b = 139};		  // rgb(72, 61, 139)
const RgbColor DARKSLATEGRAY = {.r = 47, .g = 79, .b = 79};			  // rgb(47, 79, 79)
const RgbColor DARKSLATEGREY = {.r = 47, .g = 79, .b = 79};			  // rgb(47, 79, 79)
const RgbColor DARKTURQUOISE = {.r = 0, .g = 206, .b = 209};		  // rgb(0, 206, 209)
const RgbColor DARKVIOLET = {.r = 148, .g = 0, .b = 211};			  // rgb(148, 0, 211)
const RgbColor DEEPPINK = {.r = 255, .g = 20, .b = 147};			  // rgb(255, 20, 147)
const RgbColor DEEPSKYBLUE = {.r = 0, .g = 191, .b = 255};			  // rgb(0, 191, 255)
const RgbColor DIMGRAY = {.r = 105, .g = 105, .b = 105};			  // rgb(105, 105, 105)
const RgbColor DIMGREY = {.r = 105, .g = 105, .b = 105};			  // rgb(105, 105, 105)
const RgbColor DODGERBLUE = {.r = 30, .g = 144, .b = 255};			  // rgb(30, 144, 255)
const RgbColor FIREBRICK = {.r = 178, .g = 34, .b = 34};			  // rgb(178, 34, 34)
const RgbColor FLORALWHITE = {.r = 255, .g = 250, .b = 240};		  // rgb(255, 250, 240)
const RgbColor FORESTGREEN = {.r = 34, .g = 139, .b = 34};			  // rgb(34, 139, 34)
const RgbColor FUCHSIA = {.r = 255, .g = 0, .b = 255};				  // rgb(255, 0, 255)
const RgbColor GAINSBORO = {.r = 220, .g = 220, .b = 220};			  // rgb(220, 220, 220)
const RgbColor GHOSTWHITE = {.r = 248, .g = 248, .b = 255};			  // rgb(248, 248, 255)
const RgbColor GOLD = {.r = 255, .g = 215, .b = 0};					  // rgb(255, 215, 0)
const RgbColor GOLDENROD = {.r = 218, .g = 165, .b = 32};			  // rgb(218, 165, 32)
const RgbColor GRAY = {.r = 128, .g = 128, .b = 128};				  // rgb(128, 128, 128)
const RgbColor GREEN = {.r = 0, .g = 128, .b = 0};					  // rgb(0, 128, 0)
const RgbColor GREENYELLOW = {.r = 173, .g = 255, .b = 47};			  // rgb(173, 255, 47)
const RgbColor GREY = {.r = 128, .g = 128, .b = 128};				  // rgb(128, 128, 128)
const RgbColor HONEYDEW = {.r = 240, .g = 255, .b = 240};			  // rgb(240, 255, 240)
const RgbColor HOTPINK = {.r = 255, .g = 105, .b = 180};			  // rgb(255, 105, 180)
const RgbColor INDIANRED = {.r = 205, .g = 92, .b = 92};			  // rgb(205, 92, 92)
const RgbColor INDIGO = {.r = 75, .g = 0, .b = 130};				  // rgb(75, 0, 130)
const RgbColor IVORY = {.r = 255, .g = 255, .b = 240};				  // rgb(255, 255, 240)
const RgbColor KHAKI = {.r = 240, .g = 230, .b = 140};				  // rgb(240, 230, 140)
const RgbColor LAVENDER = {.r = 230, .g = 230, .b = 250};			  // rgb(230, 230, 250)
const RgbColor LAVENDERBLUSH = {.r = 255, .g = 240, .b = 245};		  // rgb(255, 240, 245)
const RgbColor LAWNGREEN = {.r = 124, .g = 252, .b = 0};			  // rgb(124, 252, 0)
const RgbColor LEMONCHIFFON = {.r = 255, .g = 250, .b = 205};		  // rgb(255, 250, 205)
const RgbColor LIGHTBLUE = {.r = 173, .g = 216, .b = 230};			  // rgb(173, 216, 230)
const RgbColor LIGHTCORAL = {.r = 240, .g = 128, .b = 128};			  // rgb(240, 128, 128)
const RgbColor LIGHTCYAN = {.r = 224, .g = 255, .b = 255};			  // rgb(224, 255, 255)
const RgbColor LIGHTGOLDENRODYELLOW = {.r = 250, .g = 250, .b = 210}; // rgb(250, 250, 210)
const RgbColor LIGHTGRAY = {.r = 211, .g = 211, .b = 211};			  // rgb(211, 211, 211)
const RgbColor LIGHTGREEN = {.r = 144, .g = 238, .b = 144};			  // rgb(144, 238, 144)
const RgbColor LIGHTGREY = {.r = 211, .g = 211, .b = 211};			  // rgb(211, 211, 211)
const RgbColor LIGHTPINK = {.r = 255, .g = 182, .b = 193};			  // rgb(255, 182, 193)
const RgbColor LIGHTSALMON = {.r = 255, .g = 160, .b = 122};		  // rgb(255, 160, 122)
const RgbColor LIGHTSEAGREEN = {.r = 32, .g = 178, .b = 170};		  // rgb(32, 178, 170)
const RgbColor LIGHTSKYBLUE = {.r = 135, .g = 206, .b = 250};		  // rgb(135, 206, 250)
const RgbColor LIGHTSLATEGRAY = {.r = 119, .g = 136, .b = 153};		  // rgb(119, 136, 153)
const RgbColor LIGHTSLATEGREY = {.r = 119, .g = 136, .b = 153};		  // rgb(119, 136, 153)
const RgbColor LIGHTSTEELBLUE = {.r = 176, .g = 196, .b = 222};		  // rgb(176, 196, 222)
const RgbColor LIGHTYELLOW = {.r = 255, .g = 255, .b = 224};		  // rgb(255, 255, 224)
const RgbColor LIME = {.r = 0, .g = 255, .b = 0};					  // rgb(0, 255, 0)
const RgbColor LIMEGREEN = {.r = 50, .g = 205, .b = 50};			  // rgb(50, 205, 50)
const RgbColor LINEN = {.r = 250, .g = 240, .b = 230};				  // rgb(250, 240, 230)
const RgbColor MAGENTA = {.r = 255, .g = 0, .b = 255};				  // rgb(255, 0, 255)
const RgbColor MAROON = {.r = 128, .g = 0, .b = 0};					  // rgb(128, 0, 0)
const RgbColor MEDIUMAQUAMARINE = {.r = 102, .g = 205, .b = 170};	  // rgb(102, 205, 170)
const RgbColor MEDIUMBLUE = {.r = 0, .g = 0, .b = 205};				  // rgb(0, 0, 205)
const RgbColor MEDIUMORCHID = {.r = 186, .g = 85, .b = 211};		  // rgb(186, 85, 211)
const RgbColor MEDIUMPURPLE = {.r = 147, .g = 112, .b = 219};		  // rgb(147, 112, 219)
const RgbColor MEDIUMSEAGREEN = {.r = 60, .g = 179, .b = 113};		  // rgb(60, 179, 113)
const RgbColor MEDIUMSLATEBLUE = {.r = 123, .g = 104, .b = 238};	  // rgb(123, 104, 238)
const RgbColor MEDIUMSPRINGGREEN = {.r = 0, .g = 250, .b = 154};	  // rgb(0, 250, 154)
const RgbColor MEDIUMTURQUOISE = {.r = 72, .g = 209, .b = 204};		  // rgb(72, 209, 204)
const RgbColor MEDIUMVIOLETRED = {.r = 199, .g = 21, .b = 133};		  // rgb(199, 21, 133)
const RgbColor MIDNIGHTBLUE = {.r = 25, .g = 25, .b = 112};			  // rgb(25, 25, 112)
const RgbColor MINTCREAM = {.r = 245, .g = 255, .b = 250};			  // rgb(245, 255, 250)
const RgbColor MISTYROSE = {.r = 255, .g = 228, .b = 225};			  // rgb(255, 228, 225)
const RgbColor MOCCASIN = {.r = 255, .g = 228, .b = 181};			  // rgb(255, 228, 181)
const RgbColor NAVAJOWHITE = {.r = 255, .g = 222, .b = 173};		  // rgb(255, 222, 173)
const RgbColor NAVY = {.r = 0, .g = 0, .b = 128};					  // rgb(0, 0, 128)
const RgbColor OLDLACE = {.r = 253, .g = 245, .b = 230};			  // rgb(253, 245, 230)
const RgbColor OLIVE = {.r = 128, .g = 128, .b = 0};				  // rgb(128, 128, 0)
const RgbColor OLIVEDRAB = {.r = 107, .g = 142, .b = 35};			  // rgb(107, 142, 35)
const RgbColor ORANGE = {.r = 255, .g = 165, .b = 0};				  // rgb(255, 165, 0)
const RgbColor ORANGERED = {.r = 255, .g = 69, .b = 0};				  // rgb(255, 69, 0)
const RgbColor ORCHID = {.r = 218, .g = 112, .b = 214};				  // rgb(218, 112, 214)
const RgbColor PALEGOLDENROD = {.r = 238, .g = 232, .b = 170};		  // rgb(238, 232, 170)
const RgbColor PALEGREEN = {.r = 152, .g = 251, .b = 152};			  // rgb(152, 251, 152)
const RgbColor PALETURQUOISE = {.r = 175, .g = 238, .b = 238};		  // rgb(175, 238, 238)
const RgbColor PALEVIOLETRED = {.r = 219, .g = 112, .b = 147};		  // rgb(219, 112, 147)
const RgbColor PAPAYAWHIP = {.r = 255, .g = 239, .b = 213};			  // rgb(255, 239, 213)
const RgbColor PEACHPUFF = {.r = 255, .g = 218, .b = 185};			  // rgb(255, 218, 185)
const RgbColor PERU = {.r = 205, .g = 133, .b = 63};				  // rgb(205, 133, 63)
const RgbColor PINK = {.r = 255, .g = 192, .b = 203};				  // rgb(255, 192, 203)
const RgbColor PLUM = {.r = 221, .g = 160, .b = 221};				  // rgb(221, 160, 221)
const RgbColor POWDERBLUE = {.r = 176, .g = 224, .b = 230};			  // rgb(176, 224, 230)
const RgbColor PURPLE = {.r = 128, .g = 0, .b = 128};				  // rgb(128, 0, 128)
const RgbColor RED = {.r = 255, .g = 0, .b = 0};					  // rgb(255, 0, 0)
const RgbColor ROSYBROWN = {.r = 188, .g = 143, .b = 143};			  // rgb(188, 143, 143)
const RgbColor ROYALBLUE = {.r = 65, .g = 105, .b = 225};			  // rgb(65, 105, 225)
const RgbColor SADDLEBROWN = {.r = 139, .g = 69, .b = 19};			  // rgb(139, 69, 19)
const RgbColor SALMON = {.r = 250, .g = 128, .b = 114};				  // rgb(250, 128, 114)
const RgbColor SANDYBROWN = {.r = 244, .g = 164, .b = 96};			  // rgb(244, 164, 96)
const RgbColor SEAGREEN = {.r = 46, .g = 139, .b = 87};				  // rgb(46, 139, 87)
const RgbColor SEASHELL = {.r = 255, .g = 245, .b = 238};			  // rgb(255, 245, 238)
const RgbColor SIENNA = {.r = 160, .g = 82, .b = 45};				  // rgb(160, 82, 45)
const RgbColor SILVER = {.r = 192, .g = 192, .b = 192};				  // rgb(192, 192, 192)
const RgbColor SKYBLUE = {.r = 135, .g = 206, .b = 235};			  // rgb(135, 206, 235)
const RgbColor SLATEBLUE = {.r = 106, .g = 90, .b = 205};			  // rgb(106, 90, 205)
const RgbColor SLATEGRAY = {.r = 112, .g = 128, .b = 144};			  // rgb(112, 128, 144)
const RgbColor SLATEGREY = {.r = 112, .g = 128, .b = 144};			  // rgb(112, 128, 144)
const RgbColor SNOW = {.r = 255, .g = 250, .b = 250};				  // rgb(255, 250, 250)
const RgbColor SPRINGGREEN = {.r = 0, .g = 255, .b = 127};			  // rgb(0, 255, 127)
const RgbColor STEELBLUE = {.r = 70, .g = 130, .b = 180};			  // rgb(70, 130, 180)
const RgbColor TAN = {.r = 210, .g = 180, .b = 140};				  // rgb(210, 180, 140)
const RgbColor TEAL = {.r = 0, .g = 128, .b = 128};					  // rgb(0, 128, 128)
const RgbColor THISTLE = {.r = 216, .g = 191, .b = 216};			  // rgb(216, 191, 216)
const RgbColor TOMATO = {.r = 255, .g = 99, .b = 71};				  // rgb(255, 99, 71)
const RgbColor TURQUOISE = {.r = 64, .g = 224, .b = 208};			  // rgb(64, 224, 208)
const RgbColor VIOLET = {.r = 238, .g = 130, .b = 238};				  // rgb(238, 130, 238)
const RgbColor WHEAT = {.r = 245, .g = 222, .b = 179};				  // rgb(245, 222, 179)
const RgbColor WHITE = {.r = 255, .g = 255, .b = 255};				  // rgb(255, 255, 255)
const RgbColor WHITESMOKE = {.r = 245, .g = 245, .b = 245};			  // rgb(245, 245, 245)
const RgbColor YELLOW = {.r = 255, .g = 255, .b = 0};				  // rgb(255, 255, 0)
const RgbColor YELLOWGREEN = {.r = 154, .g = 205, .b = 50};			  // rgb(154, 205, 50)

#endif /* IMAGECOMPARER_H */
