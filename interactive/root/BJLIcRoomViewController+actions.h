//
//  BJLIcRoomViewController+actions.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRoomViewController (actions)

- (void)makeActions;
#if DEBUG
- (void)makeDebugActions;
#endif

- (void)switchToGalleryLayout;
- (void)switchToBlackboardLayout;
- (BOOL)updateRecordingAudio:(BOOL)on;
- (BOOL)updateRecordingVideo:(BOOL)on;
- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video;
- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video internal:(BOOL)internal;
- (void)activeCurrentLoginUser;
- (void)remakeToolboxViewControllerWithCurrentDocumentDisplayInfo:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
