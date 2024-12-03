module Main where

import Data.ByteString.Char8 qualified as BSC
import Data.ByteString.Short qualified as SBS
import Data.Hex qualified as Hex
import PlutusTx.Builtins qualified as Builtins
import System.Environment (getArgs)
import Validator qualified
import Prelude

main :: IO ()
main = do
    args <- getArgs
    case args of
        [] -> putStrLn "First argument must be a vkey."
        vkey : _ -> do
            vkey' <- either error pure $ Hex.unhex $ BSC.pack vkey
            let vkey'' = Builtins.toBuiltin vkey'
            print $ either error (Hex.hex . SBS.fromShort) $ Validator.script vkey''
