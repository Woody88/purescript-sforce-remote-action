module Test.RemoteActionSpec where 

import Prelude

import Control.Monad.Except (runExceptT)
import Control.Monad.Reader (runReaderT)
import Control.Monad.Error.Class (try)
import Control.Plus (empty)
import Data.Bifunctor (lmap)
import Data.Either (Either, isLeft)
import Data.Function.Uncurried (Fn2, Fn3)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Maybe (Maybe(..), isNothing)
import Data.Traversable (for)
import Effect.Aff (Aff, launchAff_)
import Effect.Class.Console (logShow)
import Foreign (Foreign)
import Foreign.Class (class Decode, class Encode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Salesforce.RemoteAction (class RemoteAction, JSVisualforce, RemoteActionError(..), Visualforce(..), VisualforceConfProp)
import Salesforce.RemoteAction as RemoteAction
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual)

spec :: Spec Unit
spec =
  describe "Remote Action" do
    it "returns nothing on no visualforce" do 
        let visualforce = getVisualforceMock RemoteAction.defaultConfig true
        (isNothing visualforce) `shouldEqual` true 

    it "returns should return error on bad controller name" do
        let maybeVisualforce = getVisualforceMock RemoteAction.defaultConfig false
        _ <- for maybeVisualforce \visualforce -> do 
                callBadController <- badMyControllerFunction visualforce $ Args [1,2,3]
                pure unit 
        pure unit 
newtype Args = Args (Array Int)
newtype Result = Result { myController :: String, result :: Args }

derive instance genericArgs :: Generic Args _
derive newtype instance encodeArgs :: Encode Args 
derive newtype instance decodeArgs :: Decode Args 

instance showArgs :: Show Args where 
    show = genericShow

derive instance genericResult :: Generic Result _

instance showResult :: Show Result where 
    show = genericShow

instance decodeResult :: Decode Result where 
    decode = genericDecode $ defaultOptions { unwrapSingleConstructors = true }

data BadMyControllerFunctionName = BadMyControllerFunctionName

instance remoteActionBadMyControllerFunctionName :: RemoteAction BadMyControllerFunctionName "MyController.badMyControllerFunctionName" Args Result


badMyControllerFunction :: Visualforce -> Args -> Aff (Either RemoteActionError Result)
badMyControllerFunction vf rec =  runReaderT (RemoteAction.invokeAction BadMyControllerFunctionName rec) vf

getVisualforceMock :: { | VisualforceConfProp} -> Boolean -> Maybe Visualforce
getVisualforceMock config b = flip Visualforce config <$> _getVisualforceMock pure empty b

foreign import _getVisualforceMock :: forall a. (a -> Maybe JSVisualforce) -> Maybe JSVisualforce -> Boolean -> Maybe JSVisualforce