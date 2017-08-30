/*
     File: AVSEExportCommand.m
 Abstract: A subclass of AVSECommand which handles AVAssetExportSession. It exports AVMutableComposition along with AVMutableVideoComposition and AVMutableAudioMix to a Quicktime movie.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "AVSEExportCommand.h"

@interface AVSEExportCommand (Internal)

- (void)writeVideoToPhotoLibrary:(NSURL *)url;

@end

@implementation AVSEExportCommand

- (void)performWithAsset:(AVAsset *)asset
{
	// Step 1
	// Create an outputURL to which the exported movie will be saved
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *outputURL = paths[0];
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
	outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
	// Remove Existing File
	[manager removeItemAtPath:outputURL error:nil];

	
	// Step 2
	// Create an export session with the composition and write the exported movie to the photo library
	self.exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPreset1280x720];

	self.exportSession.videoComposition = self.mutableVideoComposition;
	self.exportSession.audioMix = self.mutableAudioMix;
	self.exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
	self.exportSession.outputFileType=AVFileTypeQuickTimeMovie;

	[self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch (self.exportSession.status) {
			case AVAssetExportSessionStatusCompleted:
//				[self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
				// Step 3
				// Notify AVSEViewController about export completion
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:AVSEExportCommandCompletionNotification
				 object:self];
                NSLog(@"Completed.");
				break;
			case AVAssetExportSessionStatusFailed:
				NSLog(@"Failed:%@",self.exportSession.error);
				break;
			case AVAssetExportSessionStatusCancelled:
				NSLog(@"Canceled:%@",self.exportSession.error);
				break;
			default:
				break;
		}
	}];
}

//2017-08-26 09:44:15.699568+0800 AVSimpleEditoriOS[6963:16105132] [aqme] 254: AQDefaultDevice (173): skipping input stream 0 0 0x0

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
    if ([self hasAccessRights]) {
//        PHPhotoLibrary *library = [[PHPhotoLibrary alloc] init];
        
        __weak typeof(self) weakSelf = self;
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (weakSelf.exportSession.status) {
                case AVAssetExportSessionStatusCompleted:
//                    if (weakSelf.resultBlock) {
//                        weakSelf.resultBlock(YES, weakSelf.inURL, weakSelf.outURL, nil);
//                    }
                    break;
                case AVAssetExportSessionStatusFailed:
//                    weakSelf.resultBlock(NO, weakSelf.inURL, weakSelf.outURL, weakSelf.exportSession.error);
                    NSLog(@"error = %@", weakSelf.exportSession.error);
                    break;
                case AVAssetExportSessionStatusCancelled:
//                    weakSelf.resultBlock(NO, weakSelf.inURL, weakSelf.outURL, nil);
                    break;
                default:
                    break;
            }
        }];
    }
    
//	[library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
//		if (error) {
//			NSLog(@"Video could not be saved");
//		}
//	}];
}

- (BOOL)hasAccessRights
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (PHAuthorizationStatusNotDetermined == status) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (PHAuthorizationStatusAuthorized == status) {
                NSLog(@"获取系统相册权限成功");
            }
        }];
    }

    if (PHAuthorizationStatusRestricted == status || PHAuthorizationStatusDenied == status) {
        return NO;
    }
    return YES;
}

@end
