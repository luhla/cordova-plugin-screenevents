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
    NSString *isLocked = @"Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmhhc0JsYW5rZWRTY3JlZW4=";
    NSData *isLockedDecoded = [[NSData alloc] initWithBase64EncodedString:isLocked options:0];
    NSString *decodedString =[[NSString alloc] initWithData:isLockedDecoded encoding:NSUTF8StringEncoding];
    int nToken = 0;
    int status = notify_register_dispatch(
                                          (char*)[decodedString UTF8String],
                                          &(nToken),
                                          dispatch_get_main_queue(),
                                          ^(int t) {
                                              uint64_t state;
                                              CDVPluginResult *pluginResult = nil;
                                              int result = notify_get_state(t, &state);
                                              notify_cancel(t);
                                              
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
                                              
                                              NSLog(@"ScrEvent [ %llu - %c - %d - %@ ]", state, t,result,resultText);
                                              if (result == NOTIFY_STATUS_OK) {
                                                  NSString *screenStatus = nil;
                                                  if (state == 0) {
                                                      screenStatus = @"SCREEN_TURNED_ON";
                                                  } else {
                                                      screenStatus = @"SCREEN_TURNED_OFF";
                                                  }
                                                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:screenStatus];
                                              } else {
                                                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Result returned result: %d", result]];
                                              }
                                              
                                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                              
                                          });
    self->_notifyToken=nToken;
    NSLog(@"ScrEvent INIT [ %d - %c - %c ]", status, nToken, self->_notifyToken );
    
    if (status != NOTIFY_STATUS_OK) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Result returned status: %d", status]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


@end
