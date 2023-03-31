cordova.define("cordova-plugin-screenevents.ScreenEvents", function(require, exports, module) {
    module.exports = {
        listenerInit: function(successCallback, errorCallback,evt) {
            cordova.exec(successCallback, errorCallback, 'ScreenEvents', 'listenerInit', [evt]);
        }
    };
});
    