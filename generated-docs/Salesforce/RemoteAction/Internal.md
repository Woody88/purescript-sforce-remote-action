## Module Salesforce.RemoteAction.Internal

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

#### `apexRequest`

``` purescript
apexRequest :: Visualforce -> ApexController -> ApexControllerArgs -> Aff (Either RemoteActionError Foreign)
```

Function which performs requests using Visuaforce data 

#### `renderRemoteActionError`

``` purescript
renderRemoteActionError :: RemoteActionError -> String
```

#### `renderRemoteActionError'`

``` purescript
renderRemoteActionError' :: RemoteActionError -> String
```

#### `_getVisualforce`

``` purescript
_getVisualforce :: forall a. (a -> Maybe JSVisualforce) -> Maybe JSVisualforce -> Maybe JSVisualforce
```

#### `_callApex`

``` purescript
_callApex :: forall conf e t b. EffectFn7 JSVisualforce String Foreign conf (e -> b) (e -> t -> b) (Foreign -> b) (EffectFnAff b)
```


