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

-- | A type class which represent a RemoteAction that has types for an action controller arguments and result 
-- | The action type will be a regular data type that one can define which will give meaning to the action.
-- | Based on the action type we can determine what controller should be call and what are the args that this controller accepts
-- | and also what type of result it returns. 
-- | Example: 
-- |    data GetPCMRecords = GetPCMRecords
-- | 
-- |    instance remoteActionGetPCMRecords :: RemoteAction GetPCMRecords "PCMController.getRecords" args result
-- | 
-- | `args` and `result` should be concrete types with Encode and Decode instance respectively.
class (IsSymbol ctrl)
    <= RemoteAction act ctrl args res
    | act -> ctrl args res

-- A typeclass with usefull Monad contraints
class (MonadAff m, MonadError RemoteActionError m, MonadReader Visualforce m)
    <= MonadRemoteAction m
 
instance monadRemoteAction :: (MonadAff m, MonadError RemoteActionError m, MonadReader Visualforce m) => MonadRemoteAction m

-- | Function that invoke the action defined by referring to contraints which holds details about the correct controller to invoke.
-- | Example: 
-- |    data PCMRequests = ..
-- |
-- |    data CreatePCMRequests = CreatePCMRequests
-- | 
-- |    instance remoteActionCreatePCMs :: RemoteAction CreatePCMRequests "PCMMassController.createRecords" PCMRequests Unit
-- |
-- |    createPCMRequest :: Visualforce -> PCMRequests -> Aff (Either RemoteActionError Unit)
-- |    createPCMRequest vf rec =  runReaderT (runExceptT $ invokeAction CreatePCMRequests rec) vf
invokeAction
  :: forall act ctrl args res m
   . RemoteAction act ctrl args res
  => Encode args 
  => Decode res
  => MonadRemoteAction m
  => act
  -> args
  -> m res
invokeAction _ args = do 
    visualforce  <- ask
    eitherResult <- liftAff $ apexRequest visualforce ctrl (encode args) 
    either throwError pure (eitherResult >>= decodeResult)

    where 
        ctrl = reflectSymbol $ SProxy :: _ ctrl
        decodeResult f = lmap (RemoteActionError <<< show) $ runExcept <<< decode $ f

