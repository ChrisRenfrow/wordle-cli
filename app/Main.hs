module Main where

import Wordle

import Data.Char (toUpper)
import qualified Data.ByteString.Lazy.Char8 as L
import Control.Monad (forM_, mapM_)
import Control.Monad.State
import System.Random
import System.Console.ANSI

main :: IO ()
main = do
  wordList <- readCSVWordList "./wordlist.csv"
  idx <- getStdRandom (randomR (0, length wordList - 1))
  let answer = wordList !! idx -- Our word to guess
  let tries = 6                -- The number of tries/guesses
  putStrLn "Welcome to Wordle CLI!\nPlease enter your first guess:"
  _ <- execStateT (guessSession tries answer) []
  putStrLn "Thanks for playing!"

readCSVWordList :: FilePath -> IO [String]
readCSVWordList path = do
  contents <- L.readFile path
  return (parseCSV contents)
    where parseCSV = map (L.unpack . L.filter (/= ',')) . L.words

printGuess :: Guess -> IO ()
printGuess guess = do
  forM_ guess $ \letter -> do
     case snd letter of
       NotInWord -> do
         setSGR [Reset]
         putChar $ fst letter
       InWord -> do
         setSGR [SetColor Background Dull Yellow]
         setSGR [SetColor Foreground Dull Black]
         putChar $ fst letter
       InPlace -> do
         setSGR [SetColor Background Dull Green]
         setSGR [SetColor Foreground Dull Black]
         putChar $ fst letter
  setSGR [Reset]

printGuesses :: [Guess] -> IO ()
printGuesses guesses = do
  putStrLn "Guesses:"
  forM_ guesses $ \g -> do
    printGuess g
    putChar '\n'
  putChar '\n'

guessToStr :: Guess -> String
guessToStr = map fst

printSuccess :: (String -> IO ()) -> String -> IO ()
printSuccess f msg =
  do setSGR [SetColor Foreground Dull Green]
     f msg
     setSGR [Reset]

printFail :: (String -> IO ()) -> String -> IO ()
printFail f msg =
  do setSGR [SetColor Foreground Dull Red]
     f msg
     setSGR [Reset]

printResults :: String -> [Guess] -> IO ()
printResults word guesses = do
  if (guessToStr (last guesses)) == word
    then printSuccess (putStrLn) "\nGreat job!\n"
    else printFail (putStrLn) "\nBetter luck next time.\n"
  putStrLn $ "Target: " ++ word ++ "\n"
  printGuesses guesses


guessSession :: Int -> String -> StateT [Guess] IO ()
guessSession maxGuesses answer =
  do guessStr <- lift getLine
     let guessMatch = getMatches answer guessStr
     modify (++ [guessMatch])
     guesses <- get
     if all (\(_,x) -> x == InPlace) guessMatch
       then lift $ printResults answer guesses
       else if length guesses < maxGuesses
            then do lift $ printGuesses guesses
                    guessSession maxGuesses answer
            else lift $ printResults answer guesses
