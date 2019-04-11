exports._getVisualforce = function(just){
    return function(nothing){
        if (typeof Visualforce !== "undefined" && 
            typeof Visualforce.remoting !== "undefined" &&
            typeof Visualforce.remoting.Manager !== "undefined") { 
            return just(Visualforce);
        }
        else {
           return nothing;
        }
    }
}

exports._callApex = function(Visualforce_,
                              fullyQualifiedApexMethodName, 
                              apexMethodParameters, 
                              apexCallConfiguration, 
                              error, 
                              exception,
                              success){
    return function (onError, onSuccess) { // and callbacks
        var responseHandler = function(result, event){
            if (event.status){
                onSuccess(success(result));
            } 
            else if(event.type === "exception"){
                onSuccess(exception(event.message)(event.where));
            }
            else 
                onSuccess(error(event.message));
        }

        if (typeof Visualforce_ !== "undefined" && 
            typeof Visualforce_.remoting !== "undefined" &&
            typeof Visualforce_.remoting.Manager !== "undefined") {
    
            var req = Visualforce_.remoting.Manager.invokeAction(fullyQualifiedApexMethodName,
                                                                apexMethodParameters,
                                                                responseHandler,
                                                                apexCallConfiguration);
        }
        else {
            onSuccess(error("Could not find Visualforce Remote Object", ""));
        }

        // Return a canceler, which is just another Aff effect.
        return function (cancelError, cancelerError, cancelerSuccess) {
            req.cancel(); // cancel the request
            cancelerSuccess(); // invoke the success callback for the canceler
        };
    }

}
