module Salesforce.RemoteAction where 

import Prelude

import Control.Monad.Error.Class (class MonadError, throwError)
import Control.Monad.Except (runExcept)
import Control.Monad.Reader (class MonadReader, ask)
import Data.Bifunctor (lmap)
import Data.Either (either)
import Data.Symbol (class IsSymbol, SProxy(..), reflectSymbol)
import Effect.Aff.Class (class MonadAff, liftAff)
import Foreign.Class (class Decode, class Encode, decode, encode)
import Salesforce.RemoteAction.Internal (apexRequest)
import Salesforce.RemoteAction.Types (RemoteActionError(..), Visualforce)

-- | Credits to Robert Porter (robertdp github name) who came up with this approach. This type class represents a RemoteAction that has types for an action, controller, arguments, and result.
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
-- |```
-- |
-- |createPCMRequest :: Visualforce -> PCMRequests -> Aff (Either RemoteActionError Unit)
-- |createPCMRequest vf rec =  runReaderT (runExceptT $ invokeAction CreatePCMRequests rec) vf
invokeAction
  :: forall act ctrl args res m.
    RemoteAction act ctrl args res
    => IsSymbol ctrl 
    => MonadAff m
    => MonadError RemoteActionError m 
    => MonadReader Visualforce m
    => Encode args 
    => Decode res
    => act
    -> args
    -> m res
invokeAction _ args = do 
    let ctrl = reflectSymbol $ SProxy :: _ ctrl
        decodeResult f = lmap (RemoteActionError <<< show) $ runExcept <<< decode $ f

    visualforce  <- ask
    eitherResult <- liftAff $ apexRequest visualforce ctrl (encode args) 
    
    either throwError pure (eitherResult >>= decodeResult)


