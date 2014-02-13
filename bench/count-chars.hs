import Criterion.Main
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.Text.StreamDecoding
import Data.Text.Encoding (decodeUtf8)

calcLen :: (S.ByteString -> DecodeResult)
        -> [S.ByteString]
        -> Int
calcLen =
    loop 0
  where
    loop total _ [] = total
    loop total dec (bs:bss) =
        total' `seq` loop total' dec' bss
      where
        DecodeResultSuccess t dec' = dec bs
        total' = total + T.length t

handleEncoding :: ( String
                  , TL.Text -> L.ByteString
                  , L.ByteString -> TL.Text
                  , S.ByteString -> DecodeResult
                  )
               -> Benchmark
handleEncoding (name, encodeLazy, decodeLazy, decodeStream) = bgroup name
    [ bench "lazy" $ whnf (TL.length . decodeLazy) lbs
    , bench "stream" $ whnf (calcLen decodeStream) bss
    ]
  where
    text = TL.pack $ concat $ replicate 10 ['\27'..'\2003']
    lbs = encodeLazy text
    bss = L.toChunks lbs

main :: IO ()
main = defaultMain $ map handleEncoding
    [ ("UTF-8", TLE.encodeUtf8, TLE.decodeUtf8, streamUtf8)
    , ("UTF-16LE", TLE.encodeUtf16LE, TLE.decodeUtf16LE, streamUtf16LE)
    , ("UTF-16BE", TLE.encodeUtf16BE, TLE.decodeUtf16BE, streamUtf16BE)
    , ("UTF-32LE", TLE.encodeUtf32LE, TLE.decodeUtf32LE, streamUtf32LE)
    , ("UTF-32BE", TLE.encodeUtf32BE, TLE.decodeUtf32BE, streamUtf32BE)
    ]