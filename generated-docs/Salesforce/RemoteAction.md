## Module Salesforce.RemoteAction

#### `RemoteAction`

``` purescript
class (IsSymbol ctrl) <= RemoteAction act ctrl args res | act -> ctrl args res
```

A type class which represent a RemoteAction that has types for an action controller arguments and result 
The action type will be a regular data type that one can define which will give meaning to the action.
Based on the action type we can determine what controller should be call and what are the args that this controller accepts
and also what type of result it returns. 
Example: 

```purescript
data GetPCMRecords = GetPCMRecords

instance remoteActionGetPCMRecords :: RemoteAction GetPCMRecords "PCMController.getRecords" args result
```

`args` and `result` should be concrete types with Encode and Decode instance respectively.

#### `MonadRemoteAction`

``` purescript
class (MonadAff m, MonadError RemoteActionError m, MonadReader Visualforce m) <= MonadRemoteAction m 
```

##### Instances
``` purescript
(MonadAff m, MonadError RemoteActionError m, MonadReader Visualforce m) => MonadRemoteAction m
```

#### `invokeAction`

``` purescript
invokeAction :: forall act ctrl args res m. RemoteAction act ctrl args res => Encode args => Decode res => MonadRemoteAction m => act -> args -> m res
```

Function that invoke the action defined by referring to contraints which holds details about the correct controller to invoke.
Example: 

```purescript 
data PCMRequests = ..

data CreatePCMRequests = CreatePCMRequests

instance remoteActionCreatePCMs :: RemoteAction CreatePCMRequests "PCMMassController.createRecords" PCMRequests Unit
```

   createPCMRequest :: Visualforce -> PCMRequests -> Aff (Either RemoteActionError Unit)
   createPCMRequest vf rec =  runReaderT (runExceptT $ invokeAction CreatePCMRequests rec) vf


