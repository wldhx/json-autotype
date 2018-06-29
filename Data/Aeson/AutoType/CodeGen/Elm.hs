{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}
-- | Wrappers for generating prologue and epilogue code in Haskell.
module Data.Aeson.AutoType.CodeGen.Elm(
    defaultElmFilename
  , writeElmModule
  , runElmModule
  ) where

import qualified Data.Text           as Text
import qualified Data.Text.IO        as Text
import           Data.Text
import qualified Data.HashMap.Strict as Map
import           Control.Arrow               (first)
import           Control.Exception (assert)
import           Data.Monoid                 ((<>))
import           System.FilePath
import           System.IO
import           System.Process                 (system)
import           System.Exit                    (ExitCode)

import           Data.Aeson.AutoType.Format
import           Data.Aeson.AutoType.Type
import           Data.Aeson.AutoType.Util
import           Data.Aeson.AutoType.CodeGen.ElmFormat

import Debug.Trace(trace)

defaultElmFilename = "JSONTypes.elm"

header :: Text -> Text
header moduleName = Text.unlines [
   Text.unwords ["module ", capitalize moduleName, " exposing(..)"]
  ,""
  ,"-- elm-package install toastal/either"
  ,"-- elm-package install NoRedInk/elm-decode-pipeline"
  ,"import Either               exposing (Either, unpack)"
  ,"import Json.Encode          exposing (..)"
  ,"import Json.Decode          exposing (..)"
  ,"import Json.Decode.Pipeline exposing (..)"
  ,""]

epilogue :: Text -> Text
epilogue toplevelName = Text.unlines []

-- | Write a Haskell module to an output file, or stdout if `-` filename is given.
writeElmModule :: FilePath -> Text -> Map.HashMap Text Type -> IO ()
writeElmModule outputFilename toplevelName types =
    withFileOrHandle outputFilename WriteMode stdout $ \hOut ->
      assert (trace extension extension == ".elm") $ do
        Text.hPutStrLn hOut $ header $ Text.pack moduleName
        -- We write types as Haskell type declarations to output handle
        Text.hPutStrLn hOut $ displaySplitTypes types
        Text.hPutStrLn hOut $ epilogue toplevelName
  where
    (moduleName, extension) =
       first normalizeTypeName'     $
       splitExtension               $
       if     outputFilename == "-"
         then defaultElmFilename
         else outputFilename
    normalizeTypeName' = Text.unpack . normalizeTypeName . Text.pack

runElmModule :: [String] -> IO ExitCode
runElmModule arguments = do
    hPutStrLn stderr "Compiling *not* running Elm module for a test."
    system $ Prelude.unwords $ ["elm", "make", Prelude.head arguments] -- ignore parsing args
