module NRCSudokuSolver

where

import Data.List
import Week4

type Row    = Int 
type Column = Int 
type Value  = Int
type Grid   = [[Value]]

positions, values :: [Int]
positions = [1..9]
values    = [1..9] 

-- Subgrids defined.
blocks, nrcBlocks :: [[Int]]
blocks = [[1..3],[4..6],[7..9]]
nrcBlocks = [[2..4],[6..8]]

-- Print SudokuGrid on screen.
showDgt :: Value -> String
showDgt 0 = " "
showDgt d = show d

showRow :: [Value] -> IO()
showRow [a1,a2,a3,a4,a5,a6,a7,a8,a9] = 
 do  putChar '|'         ; putChar ' '
     putStr (showDgt a1) ; putChar ' '
     putStr (showDgt a2) ; putChar ' '
     putStr (showDgt a3) ; putChar ' '
     putChar '|'         ; putChar ' '
     putStr (showDgt a4) ; putChar ' '
     putStr (showDgt a5) ; putChar ' '
     putStr (showDgt a6) ; putChar ' '
     putChar '|'         ; putChar ' '
     putStr (showDgt a7) ; putChar ' '
     putStr (showDgt a8) ; putChar ' '
     putStr (showDgt a9) ; putChar ' '
     putChar '|'         ; putChar '\n'

showGrid :: Grid -> IO()
showGrid [as,bs,cs,ds,es,fs,gs,hs,is] =
 do putStrLn ("+-------+-------+-------+")
    showRow as; showRow bs; showRow cs
    putStrLn ("+-------+-------+-------+")
    showRow ds; showRow es; showRow fs
    putStrLn ("+-------+-------+-------+")
    showRow gs; showRow hs; showRow is
    putStrLn ("+-------+-------+-------+")

type Sudoku = (Row,Column) -> Value

showSudoku :: Sudoku -> IO()
showSudoku = showGrid . sud2grid

-- Convert Sudoku to Grid.
sud2grid :: Sudoku -> Grid
sud2grid s = 
  [ [ s (r,c) | c <- [1..9] ] | r <- [1..9] ] 

-- Convert Grid to Sudoku.
grid2sud :: Grid -> Sudoku
grid2sud gr = \ (r,c) -> pos gr (r,c) 
  where 
  pos :: [[a]] -> (Row,Column) -> a 
  pos gr (r,c) = (gr !! (r-1)) !! (c-1)

-- Get subgrid rows/column by row/column.
bl,nrcBlock :: Int -> [Int]
bl x = concat $ filter (elem x) blocks 
nrcBlock x = concat $ filter (elem x) nrcBlocks 

-- Get the digits filled in in the Sudoku for the subgrid for the given coordinates.
subGrid, nrcSubGrid :: Sudoku -> (Row,Column) -> [Value]
subGrid s (r,c) = [ s (r',c') | r' <- bl r, c' <- bl c ]
nrcSubGrid s (r,c) = [ s (r',c') | r' <- nrcBlock r, c' <- nrcBlock c ]

freeInSeq :: [Value] -> [Value]
freeInSeq seq = values \\ seq 

-- Get the free digits for a specific row
freeInRow :: Sudoku -> Row -> [Value]
freeInRow s r = 
  freeInSeq [ s (r,i) | i <- positions  ]

-- Get the free digits for a specific column
freeInColumn :: Sudoku -> Column -> [Value]
freeInColumn s c = 
  freeInSeq [ s (i,c) | i <- positions ]

-- Get free digits for the subgrid for the given coordinates.
freeInSubgrid, nrcFreeInSubgrid :: Sudoku -> (Row,Column) -> [Value]
freeInSubgrid s (r,c) = freeInSeq (subGrid s (r,c))
nrcFreeInSubgrid s (r,c) = freeInSeq (nrcSubGrid s (r,c))

-- Get the digits that can be filled in for a given coordinate.
freeAtPos :: Sudoku -> (Row,Column) -> [Value]
freeAtPos s (r,c) = 
  (freeInRow s r) 
   `intersect` (freeInColumn s c) 
   `intersect` (freeInSubgrid s (r,c)) 
   `intersect` (nrcFreeInSubgrid s (r,c)) 

injective :: Eq a => [a] -> Bool
injective xs = nub xs == xs

rowInjective :: Sudoku -> Row -> Bool
rowInjective s r = injective vs where 
   vs = filter (/= 0) [ s (r,i) | i <- positions ]

colInjective :: Sudoku -> Column -> Bool
colInjective s c = injective vs where 
   vs = filter (/= 0) [ s (i,c) | i <- positions ]

subgridInjective, nrcSubgridInjective :: Sudoku -> (Row,Column) -> Bool
subgridInjective s (r,c) = injective vs where 
   vs = filter (/= 0) (subGrid s (r,c))
nrcSubgridInjective s (r,c) = injective vs where 
   vs = filter (/= 0) (nrcSubGrid s (r,c))

consistent :: Sudoku -> Bool
consistent s = and $
               [ rowInjective s r |  r <- positions ]
                ++
               [ colInjective s c |  c <- positions ]
                ++
               [ subgridInjective s (r,c) | 
                    r <- [1,4,7], c <- [1,4,7]]
                ++
               [ nrcSubgridInjective s (r,c) | 
                    r <- [2,6], c <- [2,6]]

extend :: Sudoku -> (Row,Column,Value) -> Sudoku
extend s (r,c,v) (i,j) | (i,j) == (r,c) = v
                       | otherwise      = s (i,j)

type Constraint = (Row,Column,[Value])

type Node = (Sudoku,[Constraint])

showNode :: Node -> IO()
showNode = showSudoku . fst

solved  :: Node -> Bool
solved = null . snd

extendNode :: Node -> Constraint -> [Node]
extendNode (s,constraints) (r,c,vs) = 
   [(extend s (r,c,v),
     sortBy length3rd $ 
         prune (r,c,v) constraints) | v <- vs ]

length3rd :: (a,b,[c]) -> (a,b,[c]) -> Ordering
length3rd (_,_,zs) (_,_,zs') = 
  compare (length zs) (length zs')

prune :: (Row,Column,Value) 
      -> [Constraint] -> [Constraint]
prune _ [] = []
prune (r,c,v) ((x,y,zs):rest)
  | r == x = (x,y,zs\\[v]) : prune (r,c,v) rest
  | c == y = (x,y,zs\\[v]) : prune (r,c,v) rest
  | sameblock (r,c) (x,y) = (x,y,zs\\[v]) : prune (r,c,v) rest
  | nrcSameblock (r,c) (x,y) = (x,y,zs\\[v]) : prune (r,c,v) rest
  | otherwise = (x,y,zs) : prune (r,c,v) rest

sameblock,nrcSameblock :: (Row,Column) -> (Row,Column) -> Bool
sameblock (r,c) (x,y) = bl r == bl x && bl c == bl y 
nrcSameblock (r,c) (x,y) = nrcBlock r == nrcBlock x && nrcBlock c == nrcBlock y 

initNode :: Grid -> [Node]
initNode gr = let s = grid2sud gr in 
              if (not . consistent) s then [] 
              else [(s, constraints s)]

openPositions :: Sudoku -> [(Row,Column)]
openPositions s = [ (r,c) | r <- positions,  
                            c <- positions, 
                            s (r,c) == 0 ]

constraints :: Sudoku -> [Constraint] 
constraints s = sortBy length3rd 
    [(r,c, freeAtPos s (r,c)) | 
                       (r,c) <- openPositions s ]

search :: (node -> [node]) 
       -> (node -> Bool) -> [node] -> [node]
search succ goal [] = []
search succ goal (x:xs) 
  | goal x    = x : search succ goal xs
  | otherwise = search succ goal ((succ x) ++ xs)

solveNs :: [Node] -> [Node]
solveNs = search succNode solved 

succNode :: Node -> [Node]
succNode (s,[]) = []
succNode (s,p:ps) = extendNode (s,ps) p 

solveAndShow :: Grid -> IO[()]
solveAndShow gr = solveShowNs (initNode gr)

solveShowNs :: [Node] -> IO[()]
solveShowNs ns = sequence $ fmap showNode (solveNs ns)

example1 :: Grid
example1 = [[5,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]]

example2 :: Grid
example2 = [[0,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]]

example3 :: Grid
example3 = [[1,0,0,0,3,0,5,0,4],
            [0,0,0,0,0,0,0,0,3],
            [0,0,2,0,0,5,0,9,8], 
            [0,0,9,0,0,0,0,3,0],
            [2,0,0,0,0,0,0,0,7],
            [8,0,3,0,9,1,0,6,0],
            [0,5,1,4,7,0,0,0,0],
            [0,0,0,3,0,0,0,0,0],
            [0,4,0,0,0,9,7,0,0]]

example4 :: Grid
example4 = [[1,2,3,4,5,6,7,8,9],
            [2,0,0,0,0,0,0,0,0],
            [3,0,0,0,0,0,0,0,0],
            [4,0,0,0,0,0,0,0,0],
            [5,0,0,0,0,0,0,0,0],
            [6,0,0,0,0,0,0,0,0],
            [7,0,0,0,0,0,0,0,0],
            [8,0,0,0,0,0,0,0,0],
            [9,0,0,0,0,0,0,0,0]]

example5 :: Grid
example5 = [[1,0,0,0,0,0,0,0,0],
            [0,2,0,0,0,0,0,0,0],
            [0,0,3,0,0,0,0,0,0],
            [0,0,0,4,0,0,0,0,0],
            [0,0,0,0,5,0,0,0,0],
            [0,0,0,0,0,6,0,0,0],
            [0,0,0,0,0,0,7,0,0],
            [0,0,0,0,0,0,0,8,0],
            [0,0,0,0,0,0,0,0,9]]

nrc_lab5 :: Grid
nrc_lab5 = [[0,0,0,3,0,0,0,0,0],
            [0,0,0,7,0,0,3,0,0],
            [2,0,0,0,0,0,0,0,8],
            [0,0,6,0,0,5,0,0,0],
            [0,9,1,6,0,0,0,0,0],
            [3,0,0,0,7,1,2,0,0],
            [0,0,0,0,0,0,0,3,1],
            [0,8,0,0,4,0,0,0,0],
            [0,0,2,0,0,0,0,0,0]]



































