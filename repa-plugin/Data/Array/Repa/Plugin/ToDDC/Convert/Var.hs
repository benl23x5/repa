
module Data.Array.Repa.Plugin.ToDDC.Convert.Var
        ( convertFatName
        , convertVarName
        , convertName
        , convertLiteral)
where
import Data.Array.Repa.Plugin.ToDDC.Convert.Base
import Data.Array.Repa.Plugin.FatName
import DDC.Base.Pretty
import Data.Char

import qualified DDC.Core.Exp            as D
import qualified DDC.Core.Compounds      as D
import qualified DDC.Core.Flow           as D

import qualified Type                   as G
import qualified Var                    as G
import qualified OccName                as OccName
import qualified Name                   as Name
import qualified Literal                as G


-- Names ----------------------------------------------------------------------
-- | Convert a FatName from a GHC variable.
convertFatName :: G.Var -> Either Fail FatName
convertFatName var
 = do   vn      <- convertVarName var
        return  $ FatName (GhcNameVar var) vn


-- | Convert a printable DDC name from a GHC variable.
convertVarName :: G.Var -> Either Fail D.Name
convertVarName var
        = convertName (G.varName var)


-- | Convert a DDC name from a GHC name.
convertName :: Name.Name -> Either Fail D.Name
convertName name
 = let  baseName = OccName.occNameString
                 $ Name.nameOccName name

        unique   = show $ Name.nameUnique name
        str      = renderPlain (text baseName <> text "_" <> text unique)

   in   case baseName of
         []             -> Left FailEmptyName
         c : _ 
          | isUpper c   -> return $ D.NameCon str
          | otherwise   -> return $ D.NameVar str


-- Literals -------------------------------------------------------------------
-- | Slurp a literal.
convertLiteral 
        :: G.Literal 
        -> Either Fail (D.DaCon FatName)

convertLiteral lit
 = case lit of
        G.MachInt i 
         -> let fn = FatName (GhcNameLiteral lit) (D.NameLitInt i)
            in  return $ D.mkDaConAlg fn tIntU'

        G.MachFloat r
         -> let fn = FatName (GhcNameLiteral lit) (D.NameLitFloat r 32)
            in  return $ D.mkDaConAlg fn tFloat32U'

        G.MachDouble r
         -> let fn = FatName (GhcNameLiteral lit) (D.NameLitFloat r 64)
            in  return $ D.mkDaConAlg fn tFloat64U'

        _ -> Left (FailUnhandledLiteral lit)


tIntU' :: D.Type FatName
tIntU'  
 = D.TCon $ D.TyConBound 
        (D.UPrim  (FatName GhcNameIntU   (D.NamePrimTyCon D.PrimTyConInt))
                  D.kData)
        D.kData


tFloat32U' :: D.Type FatName
tFloat32U' 
 = D.TCon $ D.TyConBound 
        (D.UPrim  (FatName GhcNameFloatU  (D.NamePrimTyCon (D.PrimTyConFloat 32)))
                  D.kData)
        D.kData


tFloat64U' :: D.Type FatName
tFloat64U'
 = D.TCon $ D.TyConBound 
        (D.UPrim  (FatName GhcNameDoubleU (D.NamePrimTyCon (D.PrimTyConFloat 64)))
                  D.kData)
        D.kData
