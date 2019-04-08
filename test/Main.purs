module Test.Main where

import Prelude

import Effect (Effect)
import Test.RemoteActionSpec as RemoteActionSpec
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (run)

main :: Effect Unit
main = run [consoleReporter] do 
  RemoteActionSpec.spec