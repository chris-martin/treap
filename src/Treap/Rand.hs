{-# LANGUAGE TypeFamilies #-}

{- | Fair implementation of the 'Treap' data structure that uses random
generator for priorities.
-}

module Treap.Rand
       ( -- * Data structure
         RandTreap (..)

         -- * Smart constructors
       , emptyWithGen
       , oneWithGen
       , empty
       , one

         -- * Interface functions
       , lookup
       , insert
       , delete
       ) where

import Prelude hiding (lookup)

import Control.DeepSeq (NFData (..))
import Data.Foldable (foldl')
import Data.Word (Word64)
import GHC.Exts (IsList (..))
import GHC.Generics (Generic)

import Treap.Pure (Treap)

import qualified System.Random.Mersenne.Pure64 as Random
import qualified Treap.Pure as Treap

----------------------------------------------------------------------------
-- Data structure and instances
----------------------------------------------------------------------------

{- | Specialized version of 'Treap' where priority has type 'Word64' and it's
generated by the stored random generator.
-}
data RandTreap k a = RandTreap
    { randTreapGen  :: !Random.PureMT
    , randTreapTree :: !(Treap k Word64 a)
    } deriving (Show, Generic, Functor, Foldable, Traversable)

{- | Pure implementation of 'RandTreap' construction functions. Uses
@'empty' :: RandTreap k a@ as a starting point. Functions have the following
time complexity:

1. 'fromList': \( O(n\ \log \ n) \)
2. 'toList': \( O(n) \)
-}
instance Ord k => IsList (RandTreap k a) where
    type Item (RandTreap k a) = (k, a)

    fromList :: [(k, a)] -> RandTreap k a
    fromList = foldl' (\t (k, a) -> insert k a t) empty

    toList :: RandTreap k a -> [(k, a)]
    toList = map (\(k, _, a) -> (k, a)) . toList . randTreapTree

instance (NFData k, NFData a) => NFData (RandTreap k a) where
    rnf RandTreap{..} = rnf randTreapTree `seq` ()

----------------------------------------------------------------------------
-- Smart constructors
----------------------------------------------------------------------------

defaultRandomGenerator :: Random.PureMT
defaultRandomGenerator = Random.pureMT 0

-- | \( O(1) \). Create empty 'RandTreap' with given random generator.
emptyWithGen :: Random.PureMT -> RandTreap k a
emptyWithGen gen = RandTreap gen Treap.Empty
{-# INLINE emptyWithGen #-}

-- | \( O(1) \). Create empty 'RandTreap' using @mkStdGen 0@.
empty :: RandTreap k a
empty = emptyWithGen defaultRandomGenerator
{-# INLINE empty #-}

-- | \( O(1) \). Create singleton 'RandTreap' with given random generator.
oneWithGen :: Random.PureMT -> k -> a -> RandTreap k a
oneWithGen gen k a =
    let (priority, newGen) = Random.randomWord64 gen
    in RandTreap newGen $ Treap.one k priority a
{-# INLINE oneWithGen #-}

-- | \( O(1) \). Create singleton 'RandTreap' using @mkStdGen 0@.
one :: k -> a -> RandTreap k a
one = oneWithGen defaultRandomGenerator
{-# INLINE one #-}

----------------------------------------------------------------------------
-- Core functions
----------------------------------------------------------------------------

-- | \( O(\log \ n) \). Lookup a value by a given key inside 'RandTreap'.
lookup :: forall k a . Ord k => k -> RandTreap k a -> Maybe a
lookup k = Treap.lookup k . randTreapTree
{-# INLINE lookup #-}

-- | \( O(\log \ n) \). Insert a value into 'RandTreap' by given key.
insert :: Ord k => k -> a -> RandTreap k a -> RandTreap k a
insert k a (RandTreap gen t) =
    let (priority, newGen) = Random.randomWord64 gen
    in RandTreap newGen $ Treap.insert k priority a t
{-# INLINE insert #-}

{- | \( O(\log \ n) \). Delete 'RandTreap' node that contains given key. If there is no
such key, 'RandTreap' remains unchanged.
-}
delete :: Ord k => k -> RandTreap k a -> RandTreap k a
delete k (RandTreap gen t) = RandTreap gen $ Treap.delete k t
{-# INLINE delete #-}
