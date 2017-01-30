#import <Foundation/Foundation.h>
#import "react_native_gtm.h"
#import "TAGContainer.h"
#import "TagContainerOpener.h"
#import "TAGDataLayer.h"
#import "GAI.h"
#import "GAIFields.h"

@interface react_native_gtm ()<TAGContainerOpenerNotifier>
@end

@implementation react_native_gtm {
    
}

RCT_EXPORT_MODULE(ReactNativeGtm);

@synthesize methodQueue = _methodQueue;

static TAGContainer *mTAGContainer;
static TAGManager *mTagManager;

RCT_EXPORT_METHOD(openContainerWithId:(NSString *)containerId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (mTAGContainer != nil  && [mTAGContainer.containerId isEqualToString:containerId]) {
        [mTAGContainer refresh];
        reject(@"GTM-openContainerWithId():", nil, RCTErrorWithMessage(@"The container is already open."));
        return;
    }
    
    if (self.isOpeningContainer) {
        reject(@"GTM-openContainerWithId():", nil, RCTErrorWithMessage(@"The Container is opening."));
        return;
    }
    mTagManager = [TAGManager instance];
    self.isOpeningContainer = resolve;
    [TAGContainerOpener openContainerWithId:containerId
                                 tagManager:mTagManager
                                   openType:kTAGOpenTypePreferFresh
                                    timeout:nil
                                   notifier:self];
}

RCT_EXPORT_METHOD(push:(NSDictionary *)data
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (mTagManager != nil) {
        [mTagManager.dataLayer push:data];
    } else {
        reject(@"GTM-push():", nil, RCTErrorWithMessage(@"The container has not be opened."));
    }
}

RCT_EXPORT_METHOD(getClientId:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:[mTAGContainer containerId]];
    NSString *gaClientId = [tracker get:kGAIClientId];
    if (gaClientId != nil) {
        resolve(gaClientId);
    } else {
        reject(@"GTM-ClientId():", nil, RCTErrorWithMessage(@"Failed to obtain client ID."));
    }
}

- (void)containerAvailable:(TAGContainer *)container {
    dispatch_async(_methodQueue, ^{
        mTAGContainer = container;
        self.isOpeningContainer(@YES);
        self.isOpeningContainer = nil;
    });
}

@end
