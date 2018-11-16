//
//  FingerPrint.m
//  PhotoFingerPrint
//
//  Created by 杨萧玉 on 2018/11/16.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "FingerPrint.h"

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

@implementation FingerPrint

+ (NSDictionary *)fingerPrintForURL:(NSURL *)url maxSize:(CGFloat)size {
    // 1. Get pixels of image
    NSDate *start = [NSDate new];
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    NSDictionary *options = @{(id)kCGImageSourceThumbnailMaxPixelSize: @(size),
                              (id)kCGImageSourceCreateThumbnailFromImageAlways: @(YES),
                              (id)kCGImageSourceCreateThumbnailWithTransform: @(YES),
                              (id)kCGImageSourceShouldCache: @(YES)
                              };
    CGImageRef inputCGImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef)options);
    NSLog(@"duration 1:%f", -[start timeIntervalSinceNow]);
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels;
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    
    
    // 2. Iterate and calculate!
    NSMutableDictionary<NSNumber *,NSNumber *> *pixelBucket = [NSMutableDictionary dictionary];
    UInt32 * currentPixel = pixels;
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            UInt32 color = *currentPixel;
            UInt32 fingerprint = [self fingerprintOfColor:color]*10+[self areaOfX:i y:j width:width height:height];
            
            pixelBucket[@(fingerprint)] = @(pixelBucket[@(fingerprint)].intValue+1);
            currentPixel++;
        }
    }
    
    free(pixels);
    
    [pixelBucket enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        pixelBucket[key] = @(obj.doubleValue/(height * width));
    }];
    NSLog(@"duration 2:%f", -[start timeIntervalSinceNow]);
    return pixelBucket;
}

+ (UInt32)fingerprintOfColor:(UInt32)color
{
    return [self areaOfComponent:R(color)]*1000+[self areaOfComponent:G(color)]*100+[self areaOfComponent:B(color)]*10+[self areaOfComponent:A(color)];
}

+ (UInt32)areaOfComponent:(UInt32)component
{
    return component/32;
}

+ (UInt32)areaOfX:(NSUInteger)x y:(NSUInteger)y width:(NSUInteger)width height:(NSUInteger)height
{
    UInt32 result = 0;
    if (x<=width/3) {
        result+=0;
    }
    else if (x<=2*width/3) {
        result+=3;
    }
    else {
        result+=6;
    }
    
    
    if (y<=height/3) {
        result+=1;
    }
    else if (y<=2*height/3) {
        result+=2;
    }
    else {
        result+=3;
    }
    
    return result;
}


@end
