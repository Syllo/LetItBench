#!/usr/bin/env stack
{- stack
   script
   --resolver haskell-snapshot.yaml
-}

{-# LANGUAGE DeriveDataTypeable #-}

import qualified Graphics.Matplotlib as PLT
import           Graphics.Matplotlib (Matplotlib, (@@), (%), o2, (#), (##))
import           Data.Aeson.Types (ToJSON)
import qualified Statistics.Sample as STAT
import qualified Data.Text as T
import           Data.Text (Text)
import qualified Data.Text.IO
import           Data.Text.Read (double)
import qualified System.Console.CmdArgs as ARG
import           System.Console.CmdArgs ((&=), Data)
import           System.Environment (getProgName)
import           System.IO (hPutStrLn, stderr)
import           System.Exit (exitFailure)
import           Data.CSV.Conduit (decodeCSV, CSVSettings(..))
import           Control.Exception.Base (SomeException)
import qualified Data.Vector as V
import           Data.Vector (Vector, (!), cons)
import qualified Data.Map as M
import           Data.Map (Map)
import qualified Data.Set as S
import           Data.Set (Set, member)
import           Data.Maybe (catMaybes, maybe, fromJust, isNothing, fromMaybe)
import qualified Data.Text.ICU as ICU
import           Data.Text.ICU (Regex)
import           Control.Monad (foldM)
import           Data.List (foldl', unzip, intercalate)

type BenchmarkName = Text
type DataName = Text
type ErrorString = String
type PlotStyle = String
type BenchFilterRegex = Regex
type DataFilterRegex = Regex
type DataMap = Map (BenchmarkName, DataName) (Vector Double)

data CmdArguments = CmdArguments { inputDataFile :: String
                                 , outFile :: Maybe String
                                 , mplStyle :: Maybe String
                                 , filterBench :: [Text]
                                 , filterData :: [Text]
                                 , plotSize :: (Double, Double)
                                 , addSpeedupFrom :: [(Text,Text,Text)]
                                 , labelOverBarRotation :: Maybe Int
                                 , labelOverBarOffset :: Maybe Int
                                 } deriving (Show, Data)


cmdLineParser :: IO (CmdArguments)
cmdLineParser = do
  progName <- getProgName
  return $ CmdArguments { inputDataFile = mempty &= (ARG.argPos 0) &= ARG.typ "InputDataFile"
                        , outFile = Nothing &= ARG.name "o" &= ARG.help "Output file name"
                        , mplStyle = Nothing &= ARG.name "S" &= ARG.help "Matplotlib style"
                        , filterBench = mempty &= ARG.name "b" &= ARG.help "Match only bench line name by regex (e.g., -b a -b b to mach a or b)"
                        , filterData = mempty &= ARG.name "d" &= ARG.help "Match only data column name by regex (e.g., -d a -d b to mach a or b)"
                        , plotSize = (210, 297) &= ARG.name "p" &= ARG.help "Plot size (x,y) in mm"
                        , addSpeedupFrom = mempty &= ARG.name "s" &= ARG.help "Compute the speedup of (a,b,c), where a is the column selector, b is the row of reference and c is helps selecting the rows from which to compute the speedup from"
                        , labelOverBarRotation = Nothing &= ARG.name "r" &= ARG.help "Rotation in degrees of the label over the bar"
                        , labelOverBarOffset = Nothing &= ARG.name "l" &= ARG.help "Rotation in degrees of the label over the bar"
                        } &= ARG.summary "GatherScript v1.0"
                          &= ARG.program progName

main :: IO ()
main = do
  cmdArgParser <- cmdLineParser
  args <- ARG.cmdArgs cmdArgParser
  file <- Data.Text.IO.readFile $ inputDataFile args
  let decoded = someExceptionToString (inputDataFile args) (decodeCSV (CSVSettings ' ' Nothing) file :: Either SomeException (Vector (Vector Text)))
  let outputFile = outFile args
  let plotInchSize = (\(a,b) -> (mmToInch a, mmToInch b)) $ plotSize args
  let eitherDataMapWithSpeedup = do dataVector <- decoded
                                    (dataNames, dataRows) <- checkVector dataVector
                                    benchRegex <- compileRegex $ filterBench args
                                    dataRegex <- compileRegex $ filterData args
                                    dataMap <- createDataMap (V.tail dataNames) dataRows
                                    speedupRegex <- mapM compileSpeedup $ addSpeedupFrom args
                                    dataMapWithSpeedup <- foldM addSpeedupTo dataMap speedupRegex
                                    pure $ (benchRegex, dataRegex ++ regexForSpeedup (addSpeedupFrom args), dataMapWithSpeedup)
  either printErrorAndFail (plotDataAsBar plotInchSize (mplStyle args) outputFile (labelOverBarRotation args) (labelOverBarOffset args)) eitherDataMapWithSpeedup
  where
    printErrorAndFail str = printError str >> exitFailure
    printError = hPutStrLn stderr
    mmToInch mm = mm / 25.4
    someExceptionToString inFile val = case val of
                                       Left someException -> Left ("Could not parse file (" ++ inFile ++ "): " ++ show someException)
                                       Right values -> Right values
    compileSpeedup (a,b,c) = (\[x,y,z] -> (x,y,z)) <$> compileRegex [a,b,c]
    regexForSpeedup speedRegex = if speedRegex == [] then [] else [ICU.regex mempty $ T.pack "^Speedup$"]

checkVector :: Vector (Vector Text) -> Either ErrorString (Vector DataName, Vector (Vector Text))
checkVector a | V.length a <= 1 = Left "The data file is either empty or only the data header is present!"
              | V.length headerNames <= 1 = Left "The data has only one column!"
              | not $ V.all (\vector -> V.length vector == dataRowLength) benchTextData = Left "Some data row is has more data than others!"
              | otherwise = pure $ (V.head a, V.tail a)
  where
    headerNames = V.head a
    benchTextData = V.tail a
    dataRowLength = V.length $ V.head benchTextData

addSpeedupTo :: DataMap -> (Regex,Regex,Regex) -> Either ErrorString DataMap
addSpeedupTo dMap (dataCol,baseRow,rowsRegex) | S.size baseRowNameSet > 1  = Left $  "[Error]: to generate speedup data, the regex for the reference value ("
                                                                                  ++ (T.unpack . ICU.pattern) baseRow
                                                                                  ++ ") must match exactly one row but is currently matching more than one"
                                              | S.size baseRowNameSet == 0 = Left $  "[Error]: to generate speedup data, the regex for the reference value ("
                                                                                  ++ (T.unpack . ICU.pattern) baseRow
                                                                                  ++ ") must match exactly one row but is currently matching none"
                                              | S.size dataNameSet > 1     = Left $  "[Error]: to generate speedup data, the regex for the data column ("
                                                                                  ++ (T.unpack . ICU.pattern) baseRow
                                                                                  ++ ") must match exactly one column but is currently matching more than one"
                                              | S.size dataNameSet == 0    = Left $  "[Error]: to generate speedup data, the regex for the data column ("
                                                                                  ++ (T.unpack . ICU.pattern) baseRow
                                                                                  ++ ") must match exactly one column but is currently matching none"
                                              | not $ member baseRowName rowNames = Left $  "[Error]: the row used as base ("
                                                                                         ++ T.unpack baseRowName
                                                                                         ++ ") is not part of the rows from which to generate the speedup ("
                                                                                         ++ show rowNames
                                                                                         ++ ")"
                                              | otherwise = Right $ foldl' (addSpeedupValues (T.pack "Speedup") referenceRowValue) dMap [(bName, dataName) | bName <- S.toList rowNames]
  where (bNames, dNames) = getBenchDataNamesSets dMap
        dataNameSet = S.filter (\dText -> maybe False (const True) $ ICU.find dataCol dText) dNames
        dataName = head . S.toList $ dataNameSet
        baseRowNameSet = S.filter (\dText -> maybe False (const True) $ ICU.find baseRow dText) bNames
        baseRowName = head . S.toList $ baseRowNameSet
        referenceRowValue = rawMean . toStatData . fromJust $ M.lookup (baseRowName, dataName) dMap
        rowNames = S.filter (\dText -> maybe False (const True) $ ICU.find rowsRegex dText) bNames

addSpeedupValues :: Text -> Double -> DataMap -> (BenchmarkName,DataName)-> DataMap
addSpeedupValues newDataName refData dMap (bName, dName) | isNothing maybeRowData = dMap
                                                         | otherwise = let meanThisData = rawMean . toStatData . fromJust $ maybeRowData in
                                                                         M.insert (bName, newDataName) (pure (refData / meanThisData)) dMap
  where maybeRowData = M.lookup (bName, dName) dMap

data StatData = StatData { statVariance :: Double
                         , statStdDev :: Double
                         } deriving Show
data BenchData = BenchData { rawMean :: Double
                           , multiRawStat :: Maybe StatData
                           } deriving Show

getBenchDataNamesSets :: DataMap -> (Set BenchmarkName, Set DataName)
getBenchDataNamesSets dmap = let keys = M.keysSet dmap in (S.map fst keys, S.map snd keys)

compileRegex :: [Text] -> Either ErrorString [Regex]
compileRegex regTexts = mapM regexOrError regTexts
  where regexOrError regexText = case ICU.regex' [ICU.CaseInsensitive, ICU.ErrorOnUnknownEscapes] regexText of
                                   Left err -> Left $ "Malformed regular expression \"" ++ T.unpack regexText ++ "\": " ++ show err
                                   Right regex -> Right $ regex

toStatData :: Vector Double -> BenchData
toStatData vect | V.length vect == 1 = BenchData (V.head vect) Nothing
                | otherwise = let (mean, variance) = STAT.meanVarianceUnb vect in
                                BenchData mean (Just $ StatData variance (sqrt variance))

createDataMap :: Vector DataName -> Vector (Vector Text) -> Either ErrorString DataMap
createDataMap dataNames rawData =  let (benchNames, lineValues) = V.foldl' concatNameData (mempty, mempty) rawData in
                                     do lineValuesDouble <- V.mapM (V.mapM textToDouble) lineValues
                                        Right $ V.ifoldl' (\theMap benchNameID dataLine ->
                                                             V.ifoldl' (\theMap' dataID dataVal ->
                                                                          let key = (benchNames ! benchNameID, dataNames ! dataID) in
                                                                            M.insertWith mappend key (pure dataVal) theMap') theMap dataLine) M.empty lineValuesDouble
  where
    splitNameData :: Vector Text -> (Text, Vector Text)
    splitNameData = (\(a,b) -> (V.head a, b)) . (V.splitAt 1)
    concatNameData (bns, lvs) rawLine = let (bn, vs) = splitNameData rawLine in (bn `cons` bns, vs `cons` lvs)

textToDouble :: Text -> Either ErrorString Double
textToDouble txt = case Data.Text.Read.double txt of
                      Left a -> Left $ "The gathered data values should be floating point: " `mappend` a
                      Right (dval , _) -> Right dval

plotDataAsBar :: (Double, Double) -> Maybe PlotStyle -> Maybe String -> Maybe Int -> Maybe Int -> ([BenchFilterRegex], [DataFilterRegex], DataMap) -> IO ()
plotDataAsBar (sizeX, sizeY) pltStyle outputFile
              labelOverRotate labelOverOffset
              (benchNamePattern, dataNamePattern, dmap) = plotProcessor
                                                        $ plotStyle
                                                        % labelOverBarHelperFun @@ [o2 "rotation" labelRotate]
                                                        % PLT.figure @@ [o2 "num" (1 :: Int), o2 "clear" True]
                                                        % genMultiBarPlots numPlotRows numPlotCols labelOverOffset dataNames benchNames dmap
                                                        % PLT.setSizeInches sizeX sizeY
                                                        % PLT.tightLayout
  where
    labelRotate = fromMaybe 90 labelOverRotate
    plotProcessor = maybe PLT.onscreen (\file -> (\pdef -> PLT.file file pdef >> return mempty)) outputFile
    --plotProcessor a = PLT.code a >>= \b -> putStrLn b
    filterByName [] = id
    filterByName regexs = S.filter (\setVal -> any (\regex -> maybe False (const True) $ ICU.find regex setVal) regexs)
    (benchNames, dataNames) = (\(l,m) -> (S.toList . (filterByName benchNamePattern) $ l, S.toList . (filterByName dataNamePattern) $ m)) $ getBenchDataNamesSets dmap
    plotStyle = maybe PLT.mp (\style -> PLT.mp # "plot.style.use('" # style # "')") pltStyle
    numPlotCols = if length dataNames > 1 then 2 else 1
    numPlotRows = let (d,r) = length dataNames `divMod` numPlotCols in if r > 0 then d + 1 else d

barWithErrs :: (ToJSON x, ToJSON y, ToJSON err) => x -> y -> err -> Matplotlib
barWithErrs xlabel height err = PLT.readData (xlabel, height, err) % PLT.mp # "ax.bar(data[0], data[1], yerr=data[2] " ## ")"
                              % PLT.mp # "ax.set_xticklabels(data[0]" ## ")" @@ [o2 "rotation" (40::Int), o2 "horizontalalignment" "right", o2 "family" "sans-serif"]

genMultiBarPlots :: Int -> Int -> Maybe Int -> [DataName] -> [BenchmarkName] -> DataMap -> Matplotlib
genMultiBarPlots nRows nCols labelOffset dns bns dmap =
  mconcat [   PLT.addSubplot nRows nCols plotId
            % PLT.title (T.unpack plotTitle)
            % barWithErrs labels ((flip (-) bottomOffset) <$> meanData) stdErrData @@ [o2 "bottom" bottomOffset]
            % plotLabelOverBar labelOffset bottomOffset
          | (plotId, plotTitle) <- ([1..] :: [Int]) `zip` dns
          , let (labels, dataVals) = unzip . catMaybes $ dataFrom bns plotTitle
          , let currData = toStatData <$> dataVals
          , let meanData = rawMean <$> currData
          , let stdErrData = errorBarValues <$> currData
          , let bottomOffset = max 0 (minimum (zipWith (-) meanData stdErrData) - (maximum meanData - minimum meanData) * 0.1)
          ]
  where
    dataFrom :: [Text] -> Text -> [Maybe (Text, Vector Double)]
    dataFrom benchNames dataName = [Just ((,) bName) <*> (M.lookup (bName,dataName) dmap) | bName <- benchNames]
    errorBarValues = (maybe 0 statStdDev) . multiRawStat

labelOverBarHelperFun :: Matplotlib
labelOverBarHelperFun = PLT.mp # intercalate "\n" [ "def add_value_labels(ax, xVals, yVals, bottomOffset, spacing=5):"
                                                  , "    (y_min,y_max) = ax.get_ylim()"
                                                  , "    for x_value, y_value in zip(xVals,yVals):"
                                                  , "        space = spacing"
                                                  , "        if y_value < 0:"
                                                  , "          if y_value < 0.25 * (y_max - y_min):"
                                                  , "            va = 'bottom'"
                                                  , "          else:"
                                                  , "            space = -space"
                                                  , "            va = 'top'"
                                                  , "        else:"
                                                  , "          if y_value > 0.75 * (y_max - y_min):"
                                                  , "            va = 'top'"
                                                  , "            space = -space"
                                                  , "          else:"
                                                  , "            va = 'bottom'"
                                                  , "        y_value = y_value + bottomOffset"
                                                  , "        y_abs = abs(y_value)"
                                                  , "        if y_abs >= 10 and y_abs < 1000:"
                                                  , "          label = \"{:.2f}\".format(y_value)"
                                                  , "        elif y_abs >= 100 and y_abs < 10000:"
                                                  , "          label = \"{:.1f}\".format(y_value)"
                                                  , "        else:"
                                                  , "          label = \"{:.3g}\".format(y_value)"
                                                  , "        ax.annotate(label, (x_value, y_value), xytext=(0, space), textcoords=\"offset points\", ha='right', va=va"
                                                  ]
                               ## ")"

plotLabelOverBar :: Maybe Int -> Double -> Matplotlib
plotLabelOverBar pointSpace bottomOffset = PLT.mp # "add_value_labels(ax, data[0], data[1], " # bottomOffset # ", spacing=" # spaceVal # ")"
  where spaceVal = fromMaybe 5 pointSpace

