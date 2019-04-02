## Module Salesforce.RemoteAction.Types

#### `JSVisualforce`

``` purescript
data JSVisualforce :: Type
```

Represents Salesforce's Visualforce remote action object.

#### `Visualforce`

``` purescript
data Visualforce
  = Visualforce JSVisualforce {  | VisualforceConfProp }
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


