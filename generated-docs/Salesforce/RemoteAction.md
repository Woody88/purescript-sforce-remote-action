## Module Salesforce.RemoteAction

#### `Visualforce`

``` purescript
data Visualforce
```

Data type which holds remote action visualforce object and config details

#### `ApexController`

``` purescript
type ApexController = String
```

Name of apex controller including namespace (fully qualified remote action name)
https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_namespaces.htm

#### `ApexControllerArgs`

``` purescript
type ApexControllerArgs = Foreign
```

#### `VisualforceConfProp`

``` purescript
type VisualforceConfProp = (buffer :: Boolean, escape :: Boolean, timeout :: Int)
```

Configuration data structure details based on Visualforce Developer Guide 
https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_configuring_request.htm

#### `ErrorMsg`

``` purescript
type ErrorMsg = String
```

#### `ErrorTrace`

``` purescript
type ErrorTrace = String
```

#### `RemoteActionError`

``` purescript
data RemoteActionError
  = RemoteActionError ErrorMsg
  | RemoteActionException ErrorMsg ErrorTrace
```

Type for Remote Action errors

#### `MonadRemoteAction`

``` purescript
class (Monad m) <= MonadRemoteAction m  where
  apexRequest :: forall args result. Encode args => Decode result => Visualforce -> ApexController -> args -> m (Either RemoteActionError result)
```

Remote Action capability Monad. This also gives flexibily to define our own Visualforce object for testing.

##### Instances
``` purescript
MonadRemoteAction Aff
```

#### `RemoteAction`

``` purescript
class RemoteAction act (ctrl :: Symbol) args res | act -> ctrl args res
```

Credit to Robert Porter (robertdp github name) who came up with this approach. This type class represents a RemoteAction that has types for an action, controller, arguments, and result.
The controller name is a `Symbol` not `String` 
The action type is a regular data type that one can define which will give meaning to the action.
Based on Robert's approach based on the action type we can determine what controller should be called, what are the args that this controller accepts,
and also what type of result it returns. 
Example: 

```purescript
data GetPCMRecords = GetPCMRecords

instance remoteActionGetPCMRecords :: RemoteAction GetPCMRecords "PCMController.getRecords" args result
```

`args` and `result` should be concrete types with Encode and Decode instance respectively.

#### `defaultConfig`

``` purescript
defaultConfig :: {  | VisualforceConfProp }
```

Configuration details based on Visualforce Developer Guide 
https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_configuring_request.htm

#### `getVisualforce`

``` purescript
getVisualforce :: {  | VisualforceConfProp } -> Maybe Visualforce
```

Returns a Visualforce type with configs provided

#### `invokeAction`

``` purescript
invokeAction :: forall act ctrl args res m. RemoteAction act ctrl args res => MonadRemoteAction m => MonadAff m => MonadError RemoteActionError m => MonadReader Visualforce m => IsSymbol ctrl => Encode args => Decode res => act -> args -> m res
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


