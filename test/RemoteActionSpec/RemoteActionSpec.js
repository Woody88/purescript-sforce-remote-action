

exports._getVisualforceMock = function(just){
    return function(nothing){
        return function(hasNoVisualforce){
            if (hasNoVisualforce){
                return nothing;
            } else {
                var invokeActionFunc = function(fullyQualifiedApexMethodName, apexMethodParameters, responseHandler, apexCallConfiguration){

                    if (fullyQualifiedApexMethodName === "MyController.myControllerFunctionName"){
                        var result = { controller: "MyController.myControllerFunctionName", result: apexMethodParameters };
                        setTimeout(function(){
                            responseHandler(result, {status: true, message: "no error", type: "rpc", where: ""});
                        }, 500);
                    }
                    else {
                        var result = { controller: "", result: apexMethodParameters };
                        setTimeout(function(){
                            responseHandler(result, {status: false, message: "Controller Not Found", type: "exception", where: "No Apex Controller"});
                        }, 500);
                    }
                } 

                var Visualforce = { remoting: { Manager: { invokeAction: invokeActionFunc } } };
                return just(Visualforce);
            }
        }
    }
}