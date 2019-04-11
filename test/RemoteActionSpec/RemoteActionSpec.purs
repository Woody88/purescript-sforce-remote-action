module Test.RemoteActionSpec where 

import Prelude

import Control.Monad.Except (runExceptT)
import Control.Monad.Reader (runReaderT)
import Control.Plus (empty)
import Data.Bifunctor (lmap)
import Data.Either (Either(..), either)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Maybe (Maybe(..), isNothing)
import Effect.Aff (Aff)
import Foreign.Class (class Decode)
import Foreign.Generic (defaultOptions, genericDecode)
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

    it "should return error on bad controller name" do
        let maybeVisualforce = getVisualforceMock RemoteAction.defaultConfig false

        case maybeVisualforce of 
            Nothing -> fail "Expected Visualforce"
            Just visualforce -> do 
                let success (RemoteActionException _ _) = pure unit
                    success _ = fail "Expected RemoteActionException"
                    failure = const $ fail "Expected Success Path"

                eitherAccounts <- getBadAccounts visualforce
                
                either success failure eitherAccounts

    it "should return correct accounts on getRecords request" do 
        let expectedAccounts = [Account {id: "someSFDCId1", name: "account1"}, Account {id: "someSFDCId2", name: "account2"}]
            expectedResult = Result $ {controller: "MyController.getAccounts", result: expectedAccounts}
            maybeVisualforce = getVisualforceMock RemoteAction.defaultConfig false

        case maybeVisualforce of 
            Nothing -> fail "Expected Visualforce"
            Just visualforce -> do 
                let onError = pure <<< lmap RemoteAction.renderRemoteActionError 
                eitherAccounts <- getAccounts visualforce >>= onError

                eitherAccounts `shouldEqual` (Right expectedResult)


-- | Representation of our expected value
newtype Account = Account { id   :: String 
                          , name :: String  
                          }

-- | Representation of the return value from our Apex function
newtype Result = Result { controller :: String, result :: Array Account }

-- | Result instances
derive instance genericResult :: Generic Result _

derive newtype instance eqResult :: Eq Result 

instance decodeResult :: Decode Result where 
    decode = genericDecode $ defaultOptions { unwrapSingleConstructors = true }

-- | Account instances
derive newtype instance eqAccount :: Eq Account 
instance showAccount :: Show Account where 
    show = genericShow

derive instance genericAccount :: Generic Account _

instance showResult :: Show Result where 
    show = genericShow

instance decodeAccount :: Decode Account where 
    decode = genericDecode $ defaultOptions { unwrapSingleConstructors = true }

-- | Data type representing the action of the apex function we are calling
-- | An other example: 
-- | ```purescript 
-- | data GetAccounts = GetAccounts 
-- | ``` 
-- | And our apex function would be something like so 
-- | ```java 
-- | public class MyController {
-- |   public List<Account> getAccounts { ... }
-- | }
data GetAccounts = GetAccounts

data ActionWithBadController = ActionWithBadController

-- | RemoteAction instance for GetAccounts
instance remoteActionGetAccounts :: RemoteAction GetAccounts "MyController.getAccounts" Unit Result

-- | RemoteAction instance for ActionWithBadController
instance remoteActionActionWithBadController :: RemoteAction ActionWithBadController "BadController.getAccounts" Unit Result

-- | Higher level function which will retrieve the accounts using our remote action
getAccounts :: Visualforce -> Aff (Either RemoteActionError Result)
getAccounts vf =  runReaderT ( runExceptT (RemoteAction.invokeAction GetAccounts unit) ) vf

-- | Higher level function which will retrieve the bad accounts using our remote action
getBadAccounts :: Visualforce -> Aff (Either RemoteActionError Result)
getBadAccounts vf =  runReaderT ( runExceptT (RemoteAction.invokeAction ActionWithBadController unit) ) vf

getVisualforceMock :: { | VisualforceConfProp} -> Boolean -> Maybe Visualforce
getVisualforceMock config b = flip Visualforce config <$> _getVisualforceMock pure empty b

foreign import _getVisualforceMock :: forall a. (a -> Maybe JSVisualforce) -> Maybe JSVisualforce -> Boolean -> Maybe JSVisualforce