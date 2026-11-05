#import <Cordova/CDVPlugin.h>

/*
 * Trvaly posluchac stavu displeje (Darwin notify). Registruje se jednou, kazdou zmenu posila
 * do JS pres keepCallback - stejne chovani jako Android verze od 2.5.6.
 */
@interface ScreenEvents : CDVPlugin

-(void)pluginInitialize;

-(void)listenerInit:(CDVInvokedUrlCommand*)command;

@end
