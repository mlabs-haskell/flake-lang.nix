module Validator where

import PlutusLedgerApi.V3 qualified as PLA
import PlutusTx qualified
import PlutusTx.Builtins qualified as Builtins
import PlutusTx.Prelude hiding (Semigroup (..), unless)
import Prelude hiding (($), (.))

{-# INLINEABLE mkValidator #-}
mkValidator ::
    BuiltinByteString ->
    BuiltinData ->
    BuiltinData ->
    BuiltinData ->
    ()
mkValidator vkey _ red _ =
    case PLA.fromBuiltinData red of
        Nothing -> PlutusTx.Prelude.error ()
        Just (msg, sig) ->
            if Builtins.verifyEcdsaSecp256k1Signature vkey msg sig
                then ()
                else PlutusTx.Prelude.error ()

-- validator :: BuiltinByteString ->  PLA.CompiledCode (BuiltinData -> BuiltinData -> BuiltinData -> PlutusTx.BuiltinUnit)
-- validator vkey =
--     $$(PlutusTx.compile [||mkValidator||])
--       `PlutusTx.applyCode` PlutusTx.liftCode vkey

script :: BuiltinByteString -> Either String PLA.SerialisedScript
script vkey = do
    validator <-
        $$(PlutusTx.compile [||mkValidator||])
            `PlutusTx.applyCode` PlutusTx.liftCodeDef vkey
    return $ PLA.serialiseCompiledCode validator

-- scriptSerial :: BuiltinByteString -> PlutusScript PlutusScriptV2
-- scriptSerial = PlutusScriptSerialised . scriptShortBs
