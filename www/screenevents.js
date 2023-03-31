module.exports = {
    listenerInit: function(successCallback, errorCallback,evt) {
        cordova.exec(successCallback, errorCallback, 'ScreenEvents', 'listenerInit', [evt]);
    }
};
