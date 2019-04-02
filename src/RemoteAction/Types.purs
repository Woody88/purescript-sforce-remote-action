module Salesforce.RemoteAction.Types where 

import Foreign (Foreign)

-- | Represents Salesforce's Visualforce remote action object.
foreign import data JSVisualforce :: Type 

-- | Data type which holds remote action visualforce object and config details
data Visualforce = Visualforce JSVisualforce { | VisualforceConfProp }

-- | Name of apex controller including namespace (fully qualified remote action name)
-- | https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_namespaces.htm
type ApexController = String 

type ApexControllerArgs = Foreign

-- | Configuration data structure details based on Visualforce Developer Guide 
-- | https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_configuring_request.htm
type VisualforceConfProp 
    = ( buffer :: Boolean
      , escape :: Boolean
      , timeout :: Int 
      ) 
type ErrorMsg   = String 
type ErrorTrace = String 

-- | Type for Remote Action errors
data RemoteActionError 
    = RemoteActionError ErrorMsg
    | RemoteActionException ErrorMsg ErrorTrace

