/*   Copyright 2013 APPNEXUS INC
 
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

#import "ANAdView.h"
#import "ANAdView+PrivateMethods.h"

#import "ANAdViewInternalDelegate.h"
#import "ANGlobal.h"
#import "ANLogging.h"

#import "UIView+ANCategory.h"

#import "ANBannerAdView.h"



#define  DEFAULT_PUBLIC_SERVICE_ANNOUNCEMENT  NO




@interface ANAdView () <ANUniversalAdFetcherDelegate, ANAdViewInternalDelegate>

@property (nonatomic, readwrite, weak)    id<ANAdDelegate>         delegate;
@property (nonatomic, readwrite, weak)    id<ANAppEventDelegate>   appEventDelegate;
@property (nonatomic, readwrite, strong)  ANUniversalAdFetcher    *universalAdFetcher;

@property (nonatomic, readwrite)  BOOL  allowSmallerSizes;

@end



@implementation ANAdView

// ANAdProtocol properties.
//
@synthesize  placementId                            = __placementId;
@synthesize  memberId                               = __memberId;
@synthesize  inventoryCode                          = __invCode;

@synthesize  shouldServePublicServiceAnnouncements  = __shouldServePublicServiceAnnouncements;
@synthesize  location                               = __location;

@synthesize  reserve                                = __reserve;
@synthesize  age                                    = __age;
@synthesize  gender                                 = __gender;
@synthesize  customKeywords                         = __customKeywords;

@synthesize  externalUid                            = __externalUid;

@synthesize  clickThroughAction                     = __clickThroughAction;
@synthesize  landingPageLoadsInBackground           = __landingPageLoadsInBackground;

@synthesize  unifiedObject                          = __unifiedObject;

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    
    if (self != nil) {
        [self initialize];
    }
    
    return self;
}

//NB  Any entry point that requires awakeFromNib must locally set the size parameters: adSize, adSizes, allowSmallerSizes.
//
- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)initialize {
    self.clipsToBounds = YES;
    
    self.universalAdFetcher = [[ANUniversalAdFetcher alloc] initWithDelegate:self];
    
    __shouldServePublicServiceAnnouncements  = DEFAULT_PUBLIC_SERVICE_ANNOUNCEMENT;
    __location                               = nil;
    __reserve                                = 0.0f;
    __customKeywords                         = [[NSMutableDictionary alloc] init];

    __clickThroughAction                     = ANClickThroughActionOpenSDKBrowser;
    __landingPageLoadsInBackground           = YES;
    }

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.universalAdFetcher stopAdLoad];
}

- (BOOL) errorCheckConfiguration
{
    NSString      *errorString  = nil;
    NSDictionary  *errorInfo    = nil;
    NSError       *error        = nil;


    //
    BOOL  placementIdValid    = [self.placementId length] >= 1;
    BOOL  inventoryCodeValid  = ([self memberId] >=1 ) && [self inventoryCode];


    if (!placementIdValid && !inventoryCodeValid) {
        NSString      *errorString  = ANErrorString(@"no_placement_id");
        NSDictionary  *errorInfo    = @{NSLocalizedDescriptionKey: errorString};
        NSError       *error        = [NSError errorWithDomain:AN_ERROR_DOMAIN code:ANAdResponseInvalidRequest userInfo:errorInfo];

        errorString  = ANErrorString(@"no_placement_id");
        errorInfo    = @{NSLocalizedDescriptionKey: errorString};
        error        = [NSError errorWithDomain:AN_ERROR_DOMAIN code:ANAdResponseInvalidRequest userInfo:errorInfo];
    }

    if ([self isKindOfClass:[ANBannerAdView class]])
    {
        ANBannerAdView  *bav  = (ANBannerAdView *)self;

        if (!bav.adSizes) {
            errorString  = ANErrorString(@"adSizes_undefined");
            errorInfo    = @{NSLocalizedDescriptionKey: errorString};
            error        = [NSError errorWithDomain:AN_ERROR_DOMAIN code:ANAdResponseInvalidRequest userInfo:errorInfo];
        }
    }


    //
    if (error) {
        ANLogError(@"%@", errorString);
        [self adRequestFailedWithError:error];

        return  NO;
    }

    return  YES;
}

- (void)loadAd
{
    if (! [self errorCheckConfiguration])  { return; }

    //
    [self.universalAdFetcher stopAdLoad];
    [self.universalAdFetcher requestAd];
    
    if (! self.universalAdFetcher)  {
        ANLogError(@"Fetcher is unallocated.  FAILED TO FETCH ad via UT.");
    }
}


- (void)loadAdFromHtml: (NSString *)html
                 width: (int)width
                height: (int)height
{
    ANUniversalTagAdServerResponse  *response  = [[ANUniversalTagAdServerResponse alloc] initWithContent: html
                                                                                                   width: width
                                                                                                  height: height ];
    [self.universalAdFetcher processAdServerResponse:response];
}

- (void)loadAdFromVast: (NSString *)xml width: (int)width
                height: (int)height
{
    ANUniversalTagAdServerResponse  *response  = [[ANUniversalTagAdServerResponse alloc] initWitXMLContent:xml width:width height:height];
    [self.universalAdFetcher processAdServerResponse:response];
}




#pragma mark - ANAdProtocol: Setter methods

- (void)setUnifiedObject:(ANSingleUnifiedObject *)unifiedObject {
    if (!unifiedObject) {
        ANLogError(@"Could not set unifiedObject");
        return;
    }
    if (unifiedObject != __unifiedObject) {
        ANLogDebug(@"Setting unifiedObject to %@", unifiedObject);
        __unifiedObject = unifiedObject;
    }
}


- (void)setPlacementId:(nullable NSString *)placementId {
    placementId = ANConvertToNSString(placementId);
    if ([placementId length] < 1) {
        ANLogError(@"Could not set placementId to non-string value");
        return;
    }
    if (placementId != __placementId) {
        ANLogDebug(@"Setting placementId to %@", placementId);
        __placementId = placementId;
    }
}


- (void)setInventoryCode:(nullable NSString *)invCode memberId:(NSInteger) memberId{
    invCode = ANConvertToNSString(invCode);
    if (invCode && invCode != __invCode) {
        ANLogDebug(@"Setting inventory code to %@", invCode);
        __invCode = invCode;
    }
    if (memberId > 0 && memberId != __memberId) {
        ANLogDebug(@"Setting member id to %d", (int) memberId);
        __memberId = memberId;
    }
}



- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(nullable NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy];
}

- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(nullable NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy
                      precision:(NSInteger)precision {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy
                                              precision:precision];
}


- (void)addCustomKeywordWithKey:(nonnull NSString *)key
                          value:(nonnull NSString *)value
{
    if (([key length] < 1) || !value) {
        return;
    }
    
    if(self.customKeywords[key] != nil){
        NSMutableArray *valueArray = (NSMutableArray *)[self.customKeywords[key] mutableCopy];
        if (![valueArray containsObject:value]) {
            [valueArray addObject:value];
        }
        self.customKeywords[key] = [valueArray copy];
    } else {
        self.customKeywords[key] = @[value];
    }
}

- (void)removeCustomKeywordWithKey:(nonnull NSString *)key
{
    if (([key length] < 1)) {
        return;
    }
    
    //check if the key exist before calling remove
    NSArray *keysArray = [self.customKeywords allKeys];
    
    if([keysArray containsObject:key]){
        [self.customKeywords removeObjectForKey:key];
    }
    
}

- (void)clearCustomKeywords
{
    [self.customKeywords removeAllObjects];
}

- (void)setClickThroughAction:(ANClickThroughAction)clickThroughAction
{
    __clickThroughAction = clickThroughAction;
}

#pragma mark - ANAdProtocol: Getter methods

- (nullable ANSingleUnifiedObject *)unifiedObject {
    ANLogDebug(@"ANSingleUnifiedObject returned %@", __unifiedObject);
    return __unifiedObject;
}

- (nullable NSString *)placementId {
    ANLogDebug(@"placementId returned %@", __placementId);
    return __placementId;
}

- (NSInteger )memberId {
    ANLogDebug(@"memberId returned %d", (int)__memberId);
    return __memberId;
}

- (nullable NSString *)inventoryCode {
    ANLogDebug(@"inventoryCode returned %@", __invCode);
    return __invCode;
}

- (nullable ANLocation *)location {
    ANLogDebug(@"location returned %@", __location);
    return __location;
}

- (BOOL)shouldServePublicServiceAnnouncements {
    ANLogDebug(@"shouldServePublicServeAnnouncements returned %d", __shouldServePublicServiceAnnouncements);
    return __shouldServePublicServiceAnnouncements;
}

- (BOOL)landingPageLoadsInBackground {
    ANLogDebug(@"landingPageLoadsInBackground returned %d", __landingPageLoadsInBackground);
    return __landingPageLoadsInBackground;
}

- (ANClickThroughAction)clickThroughAction {
    ANLogDebug(@"clickThroughAction returned %lu", (unsigned long)__clickThroughAction);
    return __clickThroughAction;
}

- (CGFloat)reserve {
    ANLogDebug(@"reserve returned %f", __reserve);
    return __reserve;
}

- (nullable NSString *)age {
    ANLogDebug(@"age returned %@", __age);
    return __age;
}

- (ANGender)gender {
    ANLogDebug(@"gender returned %lu", (long unsigned)__gender);
    return __gender;
}

-(nullable NSString *)externalUid {
    ANLogDebug(@"ExternalUid returned %@", __externalUid);
    return __externalUid;
}

#pragma mark - ANUniversalAdFetcherDelegate  -- abstract methods.

- (void)       universalAdFetcher: (ANUniversalAdFetcher *)fetcher
     didFinishRequestWithResponse: (ANAdFetcherResponse *)response
{
    ANLogError(@"ABSTRACT METHOD -- Implement in each entrypoint.");
}

- (NSArray<NSValue *> *)adAllowedMediaTypes
{
    ANLogError(@"ABSTRACT METHOD -- Implement in each entrypoint.");
    return  nil;
}
- (BOOL)enableNativeRendering
{
    ANLogDebug(@"ABSTRACT METHOD -- Implement in Banner entrypoint");
    return NO;
}
- (NSInteger)nativeAdRendererId
{
    ANLogDebug(@"ABSTRACT METHOD -- Implement in Banner and Native entrypoint");
    return 0;
}
- (NSDictionary *) internalDelegateUniversalTagSizeParameters
{
    ANLogError(@"ABSTRACT METHOD -- Implement in each entrypoint.");
    return  nil;
}

- (CGSize)requestedSizeForAdFetcher:(ANUniversalAdFetcher *)fetcher
{
    ANLogError(@"ABSTRACT METHOD -- Implement in each entrypoint.");
    return  CGSizeMake(-1, -1);
}

- (ANVideoAdSubtype) videoAdTypeForAdFetcher:(ANUniversalAdFetcher *)fetcher
{
    ANLogWarn(@"ABSTRACT METHOD -- Implement in each entrypoint.");
    return  ANVideoAdSubtypeUnknown;
}




#pragma mark - ANAdViewInternalDelegate

- (void)adWasClicked {
    if ([self.delegate respondsToSelector:@selector(adWasClicked:)]) {
        [self.delegate adWasClicked:self];
    }
}

- (void)adWasClickedWithURL:(NSString *)urlString {
    if ([self.delegate respondsToSelector:@selector(adWasClicked:withURL:)]) {
        [self.delegate adWasClicked:self withURL:urlString];
    }
}

- (void)adWillPresent {
    if ([self.delegate respondsToSelector:@selector(adWillPresent:)]) {
        [self.delegate adWillPresent:self];
    }
}

- (void)adDidPresent {
    if ([self.delegate respondsToSelector:@selector(adDidPresent:)]) {
        [self.delegate adDidPresent:self];
    }
}

- (void)adWillClose {
    if ([self.delegate respondsToSelector:@selector(adWillClose:)]) {
        [self.delegate adWillClose:self];
    }
}

- (void)adDidClose {
    if ([self.delegate respondsToSelector:@selector(adDidClose:)]) {
        [self.delegate adDidClose:self];
    }
}

- (void)adWillLeaveApplication {
    if ([self.delegate respondsToSelector:@selector(adWillLeaveApplication:)]) {
        [self.delegate adWillLeaveApplication:self];
    }
}

- (void)adDidReceiveAppEvent:(NSString *)name withData:(NSString *)data {
    if ([self.appEventDelegate respondsToSelector:@selector(ad:didReceiveAppEvent:withData:)]) {
        [self.appEventDelegate ad:self didReceiveAppEvent:name withData:data];
    }
}

- (void)adDidReceiveAd:(id)adObject
{
    if ([self.delegate respondsToSelector:@selector(adDidReceiveAd:)]) {
        [self.delegate adDidReceiveAd:adObject];
    }
}

- (void)ad:(id)loadInstance didReceiveNativeAd:(id)responseInstance
{
    if ([self.delegate respondsToSelector:@selector(ad:didReceiveNativeAd:)]) {
        [self.delegate ad:loadInstance didReceiveNativeAd:responseInstance];
    }
}

- (void)adRequestFailedWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(ad: requestFailedWithError:)]) {
        [self.delegate ad:self requestFailedWithError:error];
    }
}

- (void)adInteractionDidBegin
{
    ANLogDebug(@"");
    [self.universalAdFetcher stopAdLoad];
}

- (void)adInteractionDidEnd
{
    ANLogDebug(@"");

    if (ANAdTypeVideo != __unifiedObject.adType) {
        [self.universalAdFetcher restartAutoRefreshTimer];
        [self.universalAdFetcher startAutoRefreshTimer];
    }
}

- (NSString *)adTypeForMRAID
{
    ANLogDebug(@"ABSTRACT METHOD.  MUST be implemented by subclass.");
    return @"";
}

- (UIViewController *)displayController
{
    ANLogDebug(@"ABSTRACT METHOD.  MUST be implemented by subclass.");
    return nil;
}


@end

