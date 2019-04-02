module Salesforce.RemoteAction.Internal where 

import Prelude

import Control.Plus (empty)
import Data.Either (Either)
import Data.Maybe (Maybe)
import Effect.Aff (Aff, throwError)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn7, runEffectFn7)
import Foreign (Foreign)
import Salesforce.RemoteAction.Types (ApexController, ApexControllerArgs, JSVisualforce, RemoteActionError(..), Visualforce(..), VisualforceConfProp)

-- | Configuration details based on Visualforce Developer Guide 
-- | https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_configuring_request.htm
defaultConfig :: { | VisualforceConfProp } 
defaultConfig = {buffer: true, escape: true, timeout: 30000}

-- | Returns a Visualforce type with configs provided
getVisualforce :: { | VisualforceConfProp } -> Maybe Visualforce
getVisualforce config =  flip Visualforce config <$> _getVisualforce pure empty

-- | Function which performs requests using Visuaforce data 
apexRequest :: Visualforce -> ApexController -> ApexControllerArgs -> Aff (Either RemoteActionError Foreign)
apexRequest (Visualforce vf c) s args = do
   effectFnAff <- liftEffect $ runEffectFn7 _callApex vf s args c (throwError <<< RemoteActionError) (\e t -> throwError $ RemoteActionException e t) pure 
   fromEffectFnAff effectFnAff

renderRemoteActionError :: RemoteActionError -> String 
renderRemoteActionError (RemoteActionError e ) = e
renderRemoteActionError (RemoteActionException e _) = e

renderRemoteActionError' :: RemoteActionError -> String 
renderRemoteActionError' (RemoteActionError e) = e
renderRemoteActionError' (RemoteActionException e t) = e <> "\n Trace: " <> t

foreign import _getVisualforce :: forall a. (a -> Maybe JSVisualforce) -> Maybe JSVisualforce -> Maybe JSVisualforce

foreign import _callApex 
    :: forall conf e t b. EffectFn7 JSVisualforce String Foreign conf (e -> b) (e -> t -> b) (Foreign -> b) (EffectFnAff b)

