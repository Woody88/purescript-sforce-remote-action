module Salesforce.RemoteAction
    ( Visualforce
    , ApexController
    , ApexControllerArgs
    , VisualforceConfProp
    , ErrorMsg
    , ErrorTrace
    , RemoteActionError (..)
    , class MonadRemoteAction 
    , class RemoteAction 
    , defaultConfig
    , getVisualforce
    , apexRequest
    , invokeAction
    )
    where 

import Prelude

import Control.Monad.Error.Class (class MonadError, throwError)
import Control.Monad.Except (runExcept)
import Control.Monad.Reader (class MonadReader, ask)
import Control.Plus (empty)
import Data.Bifunctor (lmap)
import Data.Either (Either, either)
import Data.Maybe (Maybe)
import Data.Symbol (class IsSymbol, SProxy(..), reflectSymbol)
import Effect.Aff (Aff)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn7, runEffectFn7)
import Foreign (Foreign)
import Foreign.Class (class Decode, class Encode, decode, encode)

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


-- | Configuration details based on Visualforce Developer Guide 
-- | https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_js_remoting_configuring_request.htm
defaultConfig :: { | VisualforceConfProp } 
defaultConfig = {buffer: true, escape: true, timeout: 30000}

-- | Returns a Visualforce type with configs provided
getVisualforce :: { | VisualforceConfProp } -> Maybe Visualforce
getVisualforce config =  flip Visualforce config <$> _getVisualforce pure empty

-- | Function which performs requests using Visuaforce (JS Object) created by Salesforce platform
callApex :: Visualforce -> ApexController -> ApexControllerArgs -> Aff (Either RemoteActionError Foreign)
callApex (Visualforce vf c) s args = do
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


-- | Remote Action capability Monad. This also gives flexibily to define our own Visualforce object for testing.
class (Monad m, RemoteAction act ctrl args result) <= MonadRemoteAction act ctrl args result m | act -> ctrl args result where 
    apexRequest :: 
        act
        -> Visualforce 
        -> args
        -> m (Either RemoteActionError result)


-- | MonadRemoactionAction instance for Aff 
instance monadRemoteActionAff :: 
    ( RemoteAction act ctrl args result
    , Encode args
    , Decode result
    , IsSymbol ctrl 
    ) => MonadRemoteAction act ctrl args result Aff where 
    apexRequest _ visualforce args = do 
        let ctrl = reflectSymbol $ SProxy :: _ ctrl
            decodeResult = lmap (RemoteActionError <<< show) <<< runExcept <<< decode

        eitherResult <- liftAff $ callApex visualforce ctrl (encode args)
    
        pure $ eitherResult >>= decodeResult

-- --     apexRequest :: Visualforce -> ApexController -> args -> Aff (Either RemoteActionError result) 
--     apexRequest vf ctrl args = do 
--         let decodeResult = lmap (RemoteActionError <<< show) <<< runExcept <<< decode 
        
--         eitherResult <- callApex vf ctrl (encode args) 

--         pure $ eitherResult >>= decodeResult


-- | Credit to Robert Porter (robertdp github name) who came up with this approach. This type class represents a RemoteAction that has types for an action, controller, arguments, and result.
-- | The controller name is a `Symbol` not `String` 
-- | The action type is a regular data type that one can define which will give meaning to the action.
-- | Based on Robert's approach based on the action type we can determine what controller should be called, what are the args that this controller accepts,
-- | and also what type of result it returns. 
-- | Example: 
-- |
-- |```purescript
-- |data GetPCMRecords = GetPCMRecords
-- | 
-- |instance remoteActionGetPCMRecords :: RemoteAction GetPCMRecords "PCMController.getRecords" args result
-- |```
-- | 
-- | `args` and `result` should be concrete types with Encode and Decode instance respectively.
class RemoteAction act (ctrl :: Symbol) args res | act -> ctrl args res

-- | Function that invoke the action defined by referring to contraints which holds details about the correct controller to invoke.
-- | Example: 
-- |
-- |```purescript 
-- |data PCMRequests = ..
-- |
-- |data CreatePCMRequests = CreatePCMRequests
-- | 
-- |instance remoteActionCreatePCMs :: RemoteAction CreatePCMRequests "PCMMassController.createRecords" PCMRequests Unit
-- |
-- |createPCMRequest :: Visualforce -> PCMRequests -> Aff (Either RemoteActionError Unit)
-- |createPCMRequest vf rec =  runReaderT (runExceptT $ invokeAction CreatePCMRequests rec) vf
-- |```
invokeAction
  :: forall act ctrl args res m.
    MonadRemoteAction act ctrl args res m 
    => MonadAff m
    => MonadError RemoteActionError m 
    => MonadReader Visualforce m
    => IsSymbol ctrl 
    => Encode args 
    => Decode res
    => act
    -> args
    -> m res
invokeAction act args = do 
    visualforce  <- ask
    eitherResult <- liftAff $ apexRequest act visualforce args
 
    either throwError pure eitherResult 


