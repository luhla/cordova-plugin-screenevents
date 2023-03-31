#import "ScreenEvents.h"
#import <Cordova/CDVPlugin.h>
#import <notify.h>

@implementation ScreenEvents

-(void)pluginInitialize
{
    _notifyToken = 0;
}


-(void)listenerInit:(CDVInvokedUrlCommand *)command
{
    NSString *evt =  [command argumentAtIndex:0];
    //NSLog(@"ScrEvent command [ %@ ]", evt );
    NSString *isLocked = nil;
    if ( [evt  isEqual: @"lock"] ) {
        //c-o-m.a-p-p-l-e.s-p-r-i-n-g-b-o-a-r-d.l-o-c-k-s-t-a-te	
        isLocked = @"Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmxvY2tzdGF0ZQ===";
    } else if ( [evt  isEqual: @"dimm"] ) {
        //c-o-m.a-p-p-l-e.i-o-k-i-t.h-i-d.d-i-s-p-l-a-y-S-t-a-t-u-s
        isLocked = @"Y29tLmFwcGxlLmlva2l0LmhpZC5kaXNwbGF5U3RhdHVz";
    } else {
        //c-o-m.a-p-p-l-e.s-p-r-i-n-g-b-o-a-r-d.h-a-s-B-l-a-n-k-e-d-S-c-r-e-e-n
        isLocked = @"Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmhhc0JsYW5rZWRTY3JlZW4=";
    }
    NSData *isLockedDecoded = [[NSData alloc] initWithBase64EncodedString:isLocked options:0];
    NSString *decodedString =[[NSString alloc] initWithData:isLockedDecoded encoding:NSUTF8StringEncoding];
    

    int nToken = 0;
    notify_register_check((char*)[decodedString UTF8String], &nToken);
    
    uint64_t nstate;
    int result = notify_get_state(nToken, &nstate);
    
    
    NSLog(@"ScrEvent state [ %@ - %llu - %d - %x ] ", evt, nstate,  nToken ,(result == NOTIFY_STATUS_OK) );
    
    
    //notify_cancel(nToken);
    
    int status = notify_register_dispatch(
                                        (char*)[decodedString UTF8String],
                                        &nToken,
                                        dispatch_get_main_queue(),
                                        ^(int cToken) {
                                            uint64_t state;
                                            CDVPluginResult *pluginResult = nil;
                                            int result = notify_get_state(cToken, &state);
                                            
                                            NSString *resultText = @"NOT SET";
                                            if (result == NOTIFY_STATUS_FAILED ) { resultText=(@"NOTIFY_STATUS_FAILED");}
                                            if (result == NOTIFY_STATUS_INVALID_FILE ) { resultText=(@"NOTIFY_STATUS_INVALID_FILE");}
                                            if (result == NOTIFY_STATUS_INVALID_NAME ) { resultText=(@"NOTIFY_STATUS_INVALID_NAME");}
                                            if (result == NOTIFY_STATUS_INVALID_PORT ) { resultText=(@"NOTIFY_STATUS_INVALID_PORT");}
                                            if (result == NOTIFY_STATUS_INVALID_REQUEST ) { resultText=(@"NOTIFY_STATUS_INVALID_REQUEST");}
                                            if (result == NOTIFY_STATUS_INVALID_SIGNAL ) { resultText=(@"NOTIFY_STATUS_INVALID_SIGNAL");}
                                            if (result == NOTIFY_STATUS_INVALID_TOKEN ) { resultText=(@"NOTIFY_STATUS_INVALID_TOKEN");}
                                            if (result == NOTIFY_STATUS_NOT_AUTHORIZED ) { resultText=(@"NOTIFY_STATUS_NOT_AUTHORIZED");}
                                            if (result == NOTIFY_STATUS_OK ) { resultText=(@"NOTIFY_STATUS_OK");}
                                            
                                            NSString *evt =  [command argumentAtIndex:0];
                                            NSString *screenStatus = nil;
                                            if (result == NOTIFY_STATUS_OK) {
                                                if (state == 0) {
                                                    if ( [evt  isEqual: @"lock"] ) {
                                                        screenStatus = @"LOCK_TURNED_OFF";
                                                    } else if ( [evt  isEqual: @"dimm"] ) {
                                                        screenStatus = @"DIMM_TURNED_ON";
                                                    } else if ( [evt  isEqual: @"scr"] ) {
                                                        screenStatus = @"SCREEN_TURNED_ON";
                                                    }
                                                } else {
                                                    if ( [evt  isEqual: @"lock"] ) {
                                                        screenStatus = @"LOCK_TURNED_ON";
                                                    } else if ( [evt  isEqual: @"dimm"] ) {
                                                        screenStatus = @"DIMM_TURNED_OFF";
                                                    } else if ( [evt  isEqual: @"scr"] ) {
                                                        screenStatus = @"SCREEN_TURNED_OFF";
                                                    }
                                                }
                                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:screenStatus];
                                            } else {
                                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Result returned result: %d", result]];
                                            }
                                            
                                            NSLog(@"ScrEvent fire  [ %@ - %@ - %llu - %c - %d - %@ ] ",evt, screenStatus, state, cToken,result,resultText);
                                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                            
                                            notify_cancel(cToken);
                                        });
    self->_notifyToken=nToken;
    NSLog(@"ScrEvent regi  [ %@ - %d - %d - %x ] ", evt, status, nToken, (status == NOTIFY_STATUS_OK) );
    
    if (status != NOTIFY_STATUS_OK) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Result returned status: %d", status]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


@end
