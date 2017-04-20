module Node.HotShots where

import Prelude
import Control.Monad.Aff (Aff, makeAff)
import Control.Monad.Eff (kind Effect, Eff)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Eff.Uncurried (mkEffFn1)
import Data.Either.Nested (Either3, either3)
import Data.Foreign (Foreign, toForeign)
import Data.Foreign.Class (class Encode, encode)
import Data.Functor.Contravariant ((>$<))
import Data.Maybe (Maybe, fromMaybe)
import Data.Op (Op(..))
import Data.Options (Option, Options, opt, optional, options)
import Data.Tuple (Tuple(..))

foreign import data HOTSHOTS :: Effect

-- | Phantom options data type
data HotShotsOptions

host :: Option HotShotsOptions String
host = opt "host"

port :: Option HotShotsOptions Int
port = opt "port"

prefix :: Option HotShotsOptions (Maybe String)
prefix = optional $ opt "prefix"

suffix :: Option HotShotsOptions (Maybe String)
suffix = optional $ opt "suffix"

globalize :: Option HotShotsOptions Boolean
globalize = opt "globalize"

cacheDns :: Option HotShotsOptions Boolean
cacheDns = opt "cacheDns"

mock :: Option HotShotsOptions Boolean
mock = opt "mock"

globalTags :: Option HotShotsOptions (Array String)
globalTags = opt "globalTags"

maxBufferSize :: Option HotShotsOptions Int
maxBufferSize = opt "maxBufferSize"

bufferFlushInterval :: Option HotShotsOptions Int
bufferFlushInterval = opt "bufferFlushInterval"

telegraf :: Option HotShotsOptions Boolean
telegraf = opt "telegraf"

errorHandler :: forall eff. Option HotShotsOptions (Maybe (Foreign -> Eff eff Unit))
errorHandler = optional $ mkEffFn1 >$< opt "errorHandler"

foreign import data Client :: Type

hotShotsClient :: forall eff. Options HotShotsOptions -> Eff (hotshots :: HOTSHOTS | eff) Client
hotShotsClient = clientImpl <<< options

type StatsDAction a = Tuple String (Op Foreign a)

statsDAction :: forall a. (Encode a) => String -> StatsDAction a
statsDAction = flip Tuple $ Op encode

increment :: StatsDAction Int
increment = statsDAction "increment"

decrement :: StatsDAction Int
decrement = statsDAction "decrement"

guage :: StatsDAction Number
guage = statsDAction "guage"

unique :: StatsDAction (Either3 String Number Int)
unique = (>$<) (either3 toForeign toForeign toForeign) <$> Tuple "unique" id

histogram :: StatsDAction Int
histogram = statsDAction "histogram"

action :: forall eff a. Client
       -> StatsDAction a
       -> String
       -> a
       -> Maybe Number
       -> Array String
       -> (Error -> Eff (hotshots :: HOTSHOTS | eff) Unit)
       -> (Int -> Eff (hotshots :: HOTSHOTS | eff) Unit)
       -> Eff (hotshots :: HOTSHOTS | eff) Unit
action client (Tuple actionName (Op toF)) metricName metricValue sampleRate = actionImpl client actionName metricName fMetricValue $ fromMaybe 1.0 sampleRate where
    fMetricValue = toF metricValue

action' :: forall eff a. Client
        -> StatsDAction a
        -> String
        -> a
        -> Maybe Number
        -> Array String
        -> Aff (hotshots :: HOTSHOTS | eff) Int
action' client act metricName metricValue sampleRate tags = makeAff $ action client act metricName metricValue sampleRate tags

close' :: forall eff. Client -> Aff (hotshots :: HOTSHOTS | eff) Unit
close' = makeAff <<< close

foreign import close :: forall eff. Client
                     -> (Error -> Eff (hotshots :: HOTSHOTS | eff) Unit)
                     -> (Unit -> Eff (hotshots :: HOTSHOTS | eff) Unit)
                     -> Eff (hotshots :: HOTSHOTS | eff) Unit
foreign import clientImpl :: forall eff. Foreign -> Eff (hotshots :: HOTSHOTS | eff) Client
foreign import actionImpl :: forall eff. Client
                          -> String
                          -> String
                          -> Foreign
                          -> Number
                          -> Array String
                          -> (Error -> Eff (hotshots :: HOTSHOTS | eff) Unit)
                          -> (Int -> Eff (hotshots :: HOTSHOTS | eff) Unit)
                          -> Eff (hotshots :: HOTSHOTS | eff) Unit
