module Restylers.Options
    ( Command(..)
    , Options(..)
    , HasOptions(..)
    , parseOptions
    )
where

import RIO

import Options.Applicative
import Restylers.Registry
import RIO.NonEmpty (some1)

data Command
    = Build (NonEmpty FilePath)
    | Test (NonEmpty FilePath)
    | Check Bool (NonEmpty FilePath)
    | Release (NonEmpty FilePath)
    deriving Show

data Options = Options
    { oRegistry :: Maybe Registry
    , oManifest :: FilePath
    , oDebug :: Bool
    , oCommand :: Command
    }
    deriving Show

class HasOptions env where
    optionsL :: Lens' env Options

parseOptions :: IO Options
parseOptions = execParser $ parse options "Process Restylers"

-- brittany-disable-next-binding

options :: Parser Options
options = Options
    <$> optional (Registry <$> strOption
        (  short 'r'
        <> long "registry"
        <> help "Registry to prefix all Docker images"
        <> metavar "PREFIX"
        ))
    <*> strOption
        (  short 'm'
        <> long "manifest"
        <> help "File to read/write released Restylers manifest"
        <> metavar "PATH"
        <> value "restylers.yaml"
        )
    <*> switch
        (  short 'd'
        <> long "debug"
        <> help "Log more verbosity"
        )
    <*> subparser
        (  command "build" (parse (Build <$> yamlsArgument) "Build Restylers")
        <> command "test" (parse (Test <$> yamlsArgument) "Test Restylers")
        <> command "check" (parse (Check <$> switch (long "write") <*> yamlsArgument) "Check Restylers")
        <> command "release" (parse (Release <$> yamlsArgument) "Release Restylers")
        )

yamlsArgument :: Parser (NonEmpty FilePath)
yamlsArgument =
    some1 (argument str (help "Path to Restyler info.yaml" <> metavar "PATH"))

parse :: Parser a -> String -> ParserInfo a
parse p d = info (p <**> helper) $ fullDesc <> progDesc d
