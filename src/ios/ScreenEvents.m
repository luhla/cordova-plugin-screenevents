#import "ScreenEvents.h"
#import <Cordova/CDVPlugin.h>
#import <notify.h>

@implementation ScreenEvents {
    int _notifyToken;        // token trvale registrace, 0 = neregistrovano
    NSString *_eventName;    // "scr" | "lock" | "dimm"
    NSString *_callbackId;   // JS callback (keepCallback), posledni predany z listenerInit
}

-(void)pluginInitialize
{
    _notifyToken = 0;
    _eventName = nil;
    _callbackId = nil;
}

/* Neverejne klice SpringBoardu, base64 kvuli review App Store. */
-(NSString *)notifyKeyForEvent:(NSString *)evt
{
    NSString *encoded = nil;
    if ([evt isEqualToString:@"lock"]) {
        //c-o-m.a-p-p-l-e.s-p-r-i-n-g-b-o-a-r-d.l-o-c-k-s-t-a-te
        encoded = @"Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmxvY2tzdGF0ZQ===";
    } else if ([evt isEqualToString:@"dimm"]) {
        //c-o-m.a-p-p-l-e.i-o-k-i-t.h-i-d.d-i-s-p-l-a-y-S-t-a-t-u-s
        encoded = @"Y29tLmFwcGxlLmlva2l0LmhpZC5kaXNwbGF5U3RhdHVz";
    } else {
        //c-o-m.a-p-p-l-e.s-p-r-i-n-g-b-o-a-r-d.h-a-s-B-l-a-n-k-e-d-S-c-r-e-e-n
        encoded = @"Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmhhc0JsYW5rZWRTY3JlZW4=";
    }
    NSData *decoded = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
    return [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
}

-(NSString *)statusForEvent:(NSString *)evt state:(uint64_t)state
{
    if (state == 0) {
        if ([evt isEqualToString:@"lock"]) { return @"LOCK_TURNED_OFF"; }
        if ([evt isEqualToString:@"dimm"]) { return @"DIMM_TURNED_ON"; }
        return @"SCREEN_TURNED_ON";
    }
    if ([evt isEqualToString:@"lock"]) { return @"LOCK_TURNED_ON"; }
    if ([evt isEqualToString:@"dimm"]) { return @"DIMM_TURNED_OFF"; }
    return @"SCREEN_TURNED_OFF";
}

/*
 * listenerInit(evt): registrace je trvala. Opakovane volani (JS si listener drive po kazde
 * udalosti znovu armoval, dnes uz jen pri startu / retry po chybe) pouze vymeni callback;
 * zadna dalsi registrace a zadny unik notify tokenu (puvodni verze registrovala pri kazdem
 * volani notify_register_check bez notify_cancel).
 */
-(void)listenerInit:(CDVInvokedUrlCommand *)command
{
    NSString *evt = [command argumentAtIndex:0 withDefault:@"scr"];
    _callbackId = [command.callbackId copy];

    if (_notifyToken != 0 && [evt isEqualToString:_eventName]) {
        NSLog(@"ScrEvent regi  [ %@ - already registered, callback replaced ]", evt);
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return;
    }

    [self unregister];
    _eventName = evt;

    int token = 0;
    __weak ScreenEvents *weakSelf = self;
    uint32_t status = notify_register_dispatch(
        [[self notifyKeyForEvent:evt] UTF8String],
        &token,
        dispatch_get_main_queue(),
        ^(int cToken) {
            [weakSelf fire:cToken];
        });

    if (status != NOTIFY_STATUS_OK) {
        NSLog(@"ScrEvent regi  [ %@ - FAILED %u ]", evt, status);
        _eventName = nil;
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:[NSString stringWithFormat:@"Result returned status: %u", status]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        _callbackId = nil;
        return;
    }
    _notifyToken = token;

    uint64_t state = 0;
    uint32_t result = notify_get_state(token, &state);
    NSLog(@"ScrEvent regi  [ %@ - token %d - state %llu - %x ]", evt, token, state, (result == NOTIFY_STATUS_OK));

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

-(void)fire:(int)cToken
{
    uint64_t state = 0;
    uint32_t result = notify_get_state(cToken, &state);
    NSString *screenStatus = (result == NOTIFY_STATUS_OK) ? [self statusForEvent:_eventName state:state] : nil;
    NSLog(@"ScrEvent fire  [ %@ - %@ - %llu - %d - %u ]", _eventName, screenStatus, state, cToken, result);

    if (_callbackId == nil) {
        return;
    }
    CDVPluginResult *pluginResult = nil;
    if (screenStatus != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:screenStatus];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:[NSString stringWithFormat:@"Result returned result: %u", result]];
    }
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

-(void)unregister
{
    if (_notifyToken != 0) {
        notify_cancel(_notifyToken);
        _notifyToken = 0;
    }
    _eventName = nil;
}

-(void)onReset
{
    [self unregister];
    _callbackId = nil;
}

-(void)dispose
{
    [self unregister];
    _callbackId = nil;
    [super dispose];
}

@end
