"use strict";

// module Node.HotShots

var StatsD = require('hot-shots');

exports.clientImpl = function clientImpl(config) {
    return function () {
        return new StatsD(config);
    };
};

exports.actionImpl = function actionImpl(client) {
    return function (actionName) {
        return function (metricName) {
            return function (metricValue) {
                return function (sampleRate) {
                    return function (tags) {
                        return function (onE) {
                            return function (onS) {
                                return function () {
                                    client[actionName](metricName, metricValue, sampleRate, tags, function (error, bytes) {
                                        if (error) {
                                            onE(error)();
                                        } else {
                                            onS(bytes)();
                                        }
                                    });
                                    return {};
                                };
                            };
                        };
                    };
                };
            };
        };
    };
};

exports.close = function close(client) {
    return function (onE) {
        return function (onS) {
            return function () {
                client.close(function (err) {
                    if (err) {
                        onE(err)();
                    } else {
                        onS({})();
                    }
                });
                return {};
            };
        };
    };
};
