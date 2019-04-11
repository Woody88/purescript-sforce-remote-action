

exports._getVisualforceMock = function(just){
    return function(nothing){
        return function(hasNoVisualforce){
            if (hasNoVisualforce){
                return nothing;
            } else {
                var invokeActionFunc = function(fullyQualifiedApexMethodName, apexMethodParameters, responseHandler, apexCallConfiguration){
                    if (fullyQualifiedApexMethodName === "MyController.getAccounts"){
                        var fakeAccounts = [{id: "someSFDCId1", name: "account1"}, {id: "someSFDCId2", name: "account2"}]
                            result = {controller: fullyQualifiedApexMethodName, result: fakeAccounts};
                        responseHandler(result, {status: true, message: "no error", type: "rpc", where: ""});
                    }
                    else {
                        var result = { myController: "", result: apexMethodParameters };
                        responseHandler(result, {status: false, message: "Apex Controller Wrong", where: "No Apex Controller", type: "exception"});
                    }
                } 

                var Visualforce = { remoting: { Manager: { invokeAction: invokeActionFunc } } };
                return just(Visualforce);
            }
        }
    }
}