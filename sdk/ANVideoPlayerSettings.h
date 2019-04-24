/*   Copyright 2019 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ANInitialAudioSetting) {
    SoundOn,
    SoundOff
};

/*
 The video player for the AdUnit (Instream & Outstream) can be configured by the publisher
 The available options that the publishers can change are the
 1. ClickThru Control changes
    1.1 Change the text for clickthru control
    1.2 Hide the control if not needed
    1.3 Remove or Change the "Ad" text
 2. Show/Hide volume control
 3. Show/Hide fullscreen control for outstream adUnit
 4. Show/Hide the topBar
 */
@interface ANVideoPlayerSettings : NSObject

//Show or Hide the ClickThru control on the video player
@property (nonatomic,assign) BOOL showClickThruControl;

//Change the clickThru text on the video player
@property (nonatomic, strong) NSString *clickThruText;

//Show or hide the "Ad" text next to the ClickThru control
@property (nonatomic,assign) BOOL showAdText;

//Change the ad text on the video player
@property (nonatomic, strong) NSString *adText;

//Show or hide the volume control on the player
@property (nonatomic,assign) BOOL showVolumeControl;

//Decide how the ad video sound starts initally (sound on or off). By default its off for instream and on for outstream
@property (nonatomic,assign) ANInitialAudioSetting initalAudio;

//Show or hide fullscreen control on the player
@property (nonatomic,assign) BOOL showFullScreenControl;

//Show or hide the top bar that has (ClickThru & Skip control)
@property (nonatomic,assign) BOOL showTopBar;

+ (instancetype)sharedInstance;


@end

NS_ASSUME_NONNULL_END
