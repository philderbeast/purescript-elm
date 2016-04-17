
-- | The collage API is for freeform graphics. You can move, rotate, scale, etc.
-- | all sorts of forms including lines, shapes, images, and elements.
-- |
-- | Collages use the same coordinate system you might see in an algebra or physics
-- | problem. The origin (0,0) is at the center of the collage, not the top left
-- | corner as in some other graphics libraries. Furthermore, the y-axis points up,
-- | so moving a form 10 units in the y-axis will move it up on screen.

module Elm.Graphics.Collage
    ( --Collage, makeCollage, collage, toElement
      Form, toForm, filled, textured, gradient, outlined, traced, text, outlinedText
    , move, moveX, moveY, scale, rotate, alpha
    , group, groupTransform
    , Shape, rect, oval, square, circle, ngon, polygon
    , Path, segment, path
    , solid, dashed, dotted, LineStyle, LineCap(..), LineJoin(..), defaultLine
    ) where


import Elm.Color (Color, Gradient, black, toCss, toCanvasGradient)
import Elm.Basics (Float)
import Elm.Text (Text, drawCanvas)
import Elm.Transform2D (Transform2D)
import Elm.Transform2D (identity, multiply, rotation, matrix) as T2D
import Elm.Graphics.Element (Element)
import Elm.Graphics.Internal (createNode, setStyle)

import Data.List (List(..), (..), (:), snoc, fromList)
import Data.List.Zipper (Zipper(..), down)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Foldable (for_)
import Data.Nullable (toMaybe)

import Unsafe.Coerce (unsafeCoerce)
import Math (pi, cos, sin)
import Math (sqrt)

import DOM (DOM)
import DOM.Node.Node (childNodes, nodeName, removeChild, appendChild)
import DOM.Node.NodeList (item)
import DOM.Node.Types (Element) as DOM
import DOM.Node.Types (Node, NodeList, elementToNode)
import DOM.Node.Element (setAttribute)
import DOM.HTML.Types (Window)
import DOM.HTML (window)

import Control.Monad.Eff (Eff, untilE)
import Control.Monad.Eff.Class (class MonadEff, liftEff)
import Control.Monad.ST (newSTRef, readSTRef, writeSTRef, runST)
import Control.Monad.State.Trans (StateT, evalStateT)
import Control.Monad.State.Class (gets, modify)
import Control.Comonad (extract)
import Control.Monad (when)
import Control.Bind ((>=>))

import Graphics.Canvas (Context2D, Canvas, CanvasPattern, CanvasElement, PatternRepeat(Repeat))

import Graphics.Canvas
    ( LineCap(..), setLineWidth, setLineCap, setStrokeStyle, setGlobalAlpha
    , setFillStyle, setPatternFillStyle, setGradientFillStyle, beginPath, getContext2D
    , lineTo, moveTo, scale, stroke, fillText, strokeText, rotate, save, transform
    , withImage, createPattern, fill, withContext, translate, drawImageFull
    ) as Canvas

import Prelude
    ( class Eq, eq, not, (<<<), Unit, unit, (||)
    , class Monad, bind, (>>=), pure, void
    , (*), (/), ($), map, (<$>), (+), (-), (<>), const
    , show, (<), (>), (&&), negate, (/=), (==), mod
    )


-- | A visual `Form` has a shape and texture. This can be anything from a red
-- | square to a circle textured with stripes.
newtype Form = Form
    { theta :: Number
    , scale :: Number
    , x :: Number
    , y :: Number
    , alpha :: Number
    , form :: BasicForm
    }


data FillStyle
    = Solid Color
    | Texture String
    | Grad Gradient

instance eqFillStyle :: Eq FillStyle where
    eq (Solid c1) (Solid c2) = eq c1 c2
    eq (Texture s1) (Texture s2) = eq s1 s2
    eq (Grad g1) (Grad g2) = eq g1 g2
    eq _ _ = false


-- | The shape of the ends of a line.
data LineCap
    = Flat
    | Round
    | Padded

instance eqLineCap :: Eq LineCap where
    eq Flat Flat = true
    eq Round Round = true
    eq Padded Padded = true
    eq _ _ = false


lineCap2Canvas :: LineCap -> Canvas.LineCap
lineCap2Canvas Flat = Canvas.Butt
lineCap2Canvas Round = Canvas.Round
lineCap2Canvas Padded = Canvas.Square


-- | The shape of the &ldquo;joints&rdquo; of a line, where each line segment
-- | meets. `Sharp` takes an argument to limit the length of the joint. This
-- | defaults to 10.
data LineJoin
    = Smooth
    | Sharp Float
    | Clipped

instance eqLineJoin :: Eq LineJoin where
    eq Smooth Smooth = true
    eq (Sharp f1) (Sharp f2) = eq f1 f2
    eq Clipped Clipped = true
    eq _ _ = false


-- TODO: Should suggest adding something like this to Graphics.Canvas
foreign import setLineJoinImpl :: ∀ e. String -> Number -> Context2D -> Eff (canvas :: Canvas | e) Context2D

-- | Set the current line join type.
setLineJoin :: ∀ e. LineJoin -> Context2D -> Eff (canvas :: Canvas | e) Context2D
setLineJoin Smooth = setLineJoinImpl "round" 10.0
setLineJoin (Sharp limit) = setLineJoinImpl "miter" limit
setLineJoin Clipped = setLineJoinImpl "bevel" 10.0


-- | All of the attributes of a line style. This lets you build up a line style
-- | however you want. You can also update existing line styles with record updates.
type LineStyle =
    { color :: Color
    , width :: Float
    , cap :: LineCap
    , join :: LineJoin
    , dashing :: List Int
    , dashOffset :: Int
    }


-- | The default line style, which is solid black with flat caps and sharp joints.
-- | You can use record updates to build the line style you
-- | want. For example, to make a thicker line, you could say:
-- |
-- |     defaultLine { width = 10 }
defaultLine :: LineStyle
defaultLine =
    { color: black
    , width: 1.0
    , cap: Flat
    , join: Sharp 10.0
    , dashing: Nil
    , dashOffset: 0
    }


-- | Create a solid line style with a given color.
solid :: Color -> LineStyle
solid clr =
    defaultLine
        { color = clr }


-- | Create a dashed line style with a given color. Dashing equals `[8,4]`.
dashed :: Color -> LineStyle
dashed clr =
    defaultLine
        { color = clr
        , dashing = (8 : 4 : Nil)
        }


-- | Create a dotted line style with a given color. Dashing equals `[3,3]`.
dotted :: Color -> LineStyle
dotted clr =
    defaultLine
        { color = clr
        , dashing = (3 : 3 : Nil)
        }


type Point =
    { x :: Float
    , y :: Float
    }


data BasicForm
    = FPath LineStyle (List Point)
    | FShape ShapeStyle (List Point)
    | FOutlinedText LineStyle Text
    | FText Text
    | FImage Int Int {top :: Int, left :: Int} String
    | FElement Element
    | FGroup Transform2D (List Form)


data ShapeStyle
    = Line LineStyle
    | Fill FillStyle


form :: BasicForm -> Form
form f =
    Form
        { theta: 0.0
        , scale: 1.0
        , x: 0.0
        , y: 0.0
        , alpha: 1.0
        , form: f
        }

fill :: FillStyle -> Shape -> Form
fill style (Shape shape) =
    form (FShape (Fill style) shape)


-- | Create a filled in shape.
filled :: Color -> Shape -> Form
filled color = fill (Solid color)


-- | Create a textured shape. The texture is described by some url and is
-- | tiled to fill the entire shape.
textured :: String -> Shape -> Form
textured src = fill (Texture src)


-- | Fill a shape with a gradient.
gradient :: Gradient -> Shape -> Form
gradient grad = fill (Grad grad)


{-| Outline a shape with a given line style. -}
outlined :: LineStyle -> Shape -> Form
outlined style (Shape shape) =
    form (FShape (Line style) shape)


-- | Trace a path with a given line style.
traced :: LineStyle -> Path -> Form
traced style (Path p) =
    form (FPath style p)


-- | Create a sprite from a sprite sheet. It cuts out a rectangle
-- | at a given position.
sprite :: Int -> Int -> {top :: Int, left :: Int} -> String -> Form
sprite a b c d = form $ FImage a b c d


-- | Turn any `Element` into a `Form`. This lets you use text, gifs, and video
-- | in your collage. This means you can move, rotate, and scale
-- | an `Element` however you want.
toForm :: Element -> Form
toForm e = form (FElement e)


-- | Flatten many forms into a single `Form`. This lets you move and rotate them
-- | as a single unit, making it possible to build small, modular components.
-- | Forms will be drawn in the order that they are listed, as in `collage`.
group :: List Form -> Form
group fs =
    form (FGroup T2D.identity fs)


-- | Flatten many forms into a single `Form` and then apply a matrix
-- | transformation. Forms will be drawn in the order that they are listed, as in
-- | `collage`.
groupTransform :: Transform2D -> List Form -> Form
groupTransform matrix fs =
    form (FGroup matrix fs)


-- | Move a form by the given amount (x, y). This is a relative translation so
-- | `(move (5,10) form)` would move `form` five pixels to the right and ten pixels up.
move :: Point -> Form -> Form
move {x, y} (Form f) =
    Form $ f
        { x = f.x + x
        , y = f.y + y
        }


-- | Move a shape in the x direction. This is relative so `(moveX 10 form)` moves
-- | `form` 10 pixels to the right.
moveX :: Float -> Form -> Form
moveX x (Form f) =
    Form $
        f { x = f.x + x }


-- | Move a shape in the y direction. This is relative so `(moveY 10 form)` moves
-- | `form` upwards by 10 pixels.
moveY :: Float -> Form -> Form
moveY y (Form f) =
    Form $
        f { y = f.y + y }


-- | Scale a form by a given factor. Scaling by 2 doubles both dimensions,
-- | and quadruples the area.
scale :: Float -> Form -> Form
scale s (Form f) =
    Form $
        f { scale = f.scale * s }


-- | Rotate a form by a given angle. Rotate takes standard Elm angles (radians)
-- | and turns things counterclockwise. So to turn `form` 30&deg; to the left
-- | you would say, `(rotate (degrees 30) form)`.
rotate :: Float -> Form -> Form
rotate t (Form f) =
    Form $
        f { theta = f.theta + t }


-- | Set the alpha of a `Form`. The default is 1, and 0 is totally transparent.
alpha :: Float -> Form -> Form
alpha a (Form f) =
    Form $
        f { alpha = a }


newtype Collage = Collage
    { w :: Int
    , h :: Int
    , forms :: List Form
    }


-- | Create a `Collage` with certain dimensions and content. It takes width and height
-- | arguments to specify dimensions, and then a list of 2D forms to decribe the content.
-- |
-- | The forms are drawn in the order of the list, i.e., `collage w h (a : b : Nil)` will
-- | draw `b` on top of `a`.
-- |
-- | Note that this normally might be called `collage`, but Elm uses that for the function
-- | that actually creates an `Element`.
makeCollage :: Int -> Int -> List Form -> Collage
makeCollage w h forms = Collage {w, h, forms}


-- | Create a collage `Element` with certain dimensions and content. It takes width and height
-- | arguments to specify dimensions, and then a list of 2D forms to decribe the content.
-- |
-- | The forms are drawn in the order of the list, i.e., `collage w h (a : b : Nil)` will
-- | draw `b` on top of `a`.
-- |
-- | To make a `Collage` without immediately turning it into an `Element`, see `makeCollage`.
-- collage :: Int -> Int -> List Form -> Element
-- collage = makeCollage >>> toElement


-- | Turn a `Collage` into an `Element`.
-- toElement :: Collage -> Element
-- toElement collage =


-- | A 2D path. Paths are a sequence of points. They do not have a color.
newtype Path = Path (List Point)


-- | Create a path that follows a sequence of points.
path :: List Point -> Path
path ps = Path ps


-- | Create a path along a given line segment.
segment :: Point -> Point -> Path
segment p1 p2 =
    Path (p1 : p2 : Nil)


-- | A 2D shape. Shapes are closed polygons. They do not have a color or
-- | texture, that information can be filled in later.
newtype Shape = Shape (List Point)


-- | Create an arbitrary polygon by specifying its corners in order.
-- | `polygon` will automatically close all shapes, so the given list
-- | of points does not need to start and end with the same position.
polygon :: List Point -> Shape
polygon = Shape


-- | A rectangle with a given width and height.
rect :: Float -> Float -> Shape
rect w h =
    let
        hw = w / 2.0
        hh = h / 2.0

    in
        Shape
            ( { x: 0.0 - hw, y: 0.0 - hh }
            : { x: 0.0 - hw, y: hh }
            : { x: hw, y: hh }
            : { x: hw, y: 0.0 - hh }
            : Nil
            )


-- | A square with a given edge length.
square :: Float -> Shape
square n = rect n n


-- | An oval with a given width and height.
oval :: Float -> Float -> Shape
oval w h =
    let
        n = 50
        t = 2.0 * pi / toNumber n
        hw = w / 2.0
        hh = h / 2.0

        f i =
            let
                ti = t * toNumber i

            in
                { x: hw * cos ti
                , y: hh * sin ti
                }

    in
        Shape $
            map f (0 .. (n - 1))


-- | A circle with a given radius.
circle :: Float -> Shape
circle r = oval (2.0 * r) (2.0 * r)


-- | A regular polygon with N sides. The first argument specifies the number
-- | of sides and the second is the radius. So to create a pentagon with radius
-- | 30 you would say:
-- |
-- |     ngon 5 30
ngon :: Int -> Float -> Shape
ngon n r =
    let
        t = 2.0 * pi / (toNumber n)
        f i =
            { x: r * cos (t * (toNumber i))
            , y: r * sin (t * (toNumber i))
            }

    in
        Shape $
            map f (0 .. (n - 1))


-- | Create some text. Details like size and color are part of the `Text` value
-- | itself, so you can mix colors and sizes and fonts easily.
text :: Text -> Form
text = form <<< FText


-- | Create some outlined text. Since we are just outlining the text, the color
-- | is taken from the `LineStyle` attribute instead of the `Text`.
outlinedText :: LineStyle -> Text -> Form
outlinedText ls t =
    form (FOutlinedText ls t)


-- RENDER


render :: ∀ e. Collage -> Eff (dom :: DOM | e) DOM.Element
render model = do
    div <- createNode "div"
    setStyle "overflow" "hidden" div
    setStyle "position" "relative" div
    -- update div model model
    pure div


setStrokeStyle :: ∀ e. LineStyle -> Context2D -> Eff (canvas :: Canvas | e) Context2D
setStrokeStyle style =
    Canvas.setLineWidth style.width >=>
    Canvas.setLineCap (lineCap2Canvas style.cap) >=>
    setLineJoin style.join >=>
    Canvas.setStrokeStyle (toCss style.color)


setFillStyle :: ∀ e. Context2D -> FillStyle -> (CanvasPattern -> Eff (canvas :: Canvas | e) Unit) -> Eff (canvas :: Canvas | e) Context2D
setFillStyle ctx style redo =
    case style of
        Solid c ->
            Canvas.setFillStyle (toCss c) ctx

        Texture t -> do
            texture ctx t \pattern -> do
                Canvas.setPatternFillStyle pattern ctx
                redo pattern
            pure ctx

        Grad g -> do
            grad <- toCanvasGradient g ctx
            Canvas.setGradientFillStyle grad ctx


-- Note that this traces first to last, whereas Elm traces from last to
-- first. If this turns out to matter, I can reverse the list.
trace :: ∀ e. Boolean -> List Point -> Context2D -> Eff (canvas :: Canvas | e) Context2D
trace closed list ctx =
    case list of
        Cons first rest -> do
            Canvas.moveTo ctx first.x first.y

            for_ rest \point ->
                Canvas.lineTo ctx point.x point.y

            if closed
                then Canvas.lineTo ctx first.x first.y
                else pure ctx

        _ ->
            pure ctx


line :: ∀ e. LineStyle -> Boolean -> List Point -> Context2D -> Eff (canvas :: Canvas | e) Context2D
line style closed pointList ctx =
    case pointList of
        -- Note that elm draws from the last point to the first, whereas we're
        -- drawing from the first to the last. If this turns out to matter, we
        -- can always start by reversing the list.
        Cons firstPoint remainingPoints -> do

            -- We have some points. So, check the dashing.
            case style.dashing of
                Cons firstDash remainingDashes ->

                    -- We have some dashing.
                    -- Note that Elm implements the Canvas `setLineDash` manually, perhaps for
                    -- back-compat with IE <11. So, we'll do it too!

                    -- The rest of this is easiest, I'm afraid, if we allow a bit of
                    -- mutation. At least, at a first approximation. I should probably
                    -- put all of this inside a state monad, but I'll try runST first.
                    -- I suppose that what's really going on here is that we're iterating
                    -- through both the points and the dashes, and each has to give up
                    -- control to the other at certain points. So, probably the right way
                    -- to do this would be with continuations. But that might be overkill.
                    runST do

                        -- The dashes are basically a list of on/off lengths which we
                        -- want to iterate through, and then go back to the beginning.
                        -- I think this is easiest with a zipper, though in fact you
                        -- could construct something even more specific. We remember
                        -- the firstPattern so we can go back to the beginning easily.
                        let firstPattern = Zipper Nil firstDash remainingDashes
                        pattern <- newSTRef firstPattern

                        -- We also need to keep track of how much is left in the current
                        -- segment of the pattern ... that is, how much length we can
                        -- draw or skip until we should look at the next segment
                        leftInPattern <- newSTRef (toNumber firstDash)

                        -- Here we keep track of whether we're drawing or not drawing.
                        -- We start by drawing.
                        drawing <- newSTRef true

                        -- And, we'll want to track where we are
                        position <- newSTRef firstPoint

                        -- First, move to our first point
                        Canvas.moveTo ctx firstPoint.x firstPoint.y

                        let
                            -- If we're closed, we add the first point to those remaining
                            points =
                                if closed
                                    then snoc remainingPoints firstPoint
                                    else remainingPoints

                        -- Now, we iterate over the points
                        for_ points \destination ->
                            untilE do
                                currentPosition <- readSTRef position
                                currentlyDrawing <- readSTRef drawing
                                currentSegment <- readSTRef leftInPattern

                                let
                                    dx = destination.x - currentPosition.x
                                    dy = destination.y - currentPosition.y
                                    distance = sqrt ((dx * dx) + (dy * dy))
                                    operation = if currentlyDrawing then Canvas.lineTo else Canvas.moveTo

                                if distance < currentSegment
                                    then do
                                        -- Aha, we'll complete this point with the current
                                        -- segment. So, first we draw or move, to our
                                        -- destination.
                                        operation ctx destination.x destination.y

                                        -- Now, we'll remain with our current segment ... but
                                        -- we've used some of it, so we decrement
                                        writeSTRef leftInPattern (currentSegment - distance)

                                        -- And record our new position
                                        writeSTRef position destination

                                        -- And, we tell the untilE that we're done with this point,
                                        -- so move to the next destination
                                        pure true

                                    else do
                                        -- We've got more distance to travel than our current segment
                                        -- length. So, first we need to calculate what position we'll
                                        -- end up with for this segment.
                                        let
                                            nextPosition =
                                                { x: currentPosition.x + (dx * currentSegment / distance)
                                                , y: currentPosition.y + (dy * currentSegment / distance)
                                                }

                                        -- So, actually do the operation
                                        operation ctx nextPosition.x nextPosition.y

                                        -- And record our new position
                                        writeSTRef position nextPosition

                                        -- Now, we've used up this segment, so we need to flip our
                                        -- drawing state.
                                        writeSTRef drawing (not currentlyDrawing)

                                        -- And get the next pattern
                                        currentPattern <- readSTRef pattern

                                        -- We go down, and if at end back to first
                                        let nextPattern = fromMaybe firstPattern (down currentPattern)

                                        writeSTRef pattern nextPattern
                                        writeSTRef leftInPattern (toNumber (extract nextPattern))

                                        -- And, tell the untilE that we're not done with this destination yet
                                        pure false

                        -- We're done all the points ... just return the ctx
                        pure ctx

                _ ->
                    -- This the case where we have no dashing, so we can just trace the line
                    trace closed pointList ctx

            -- In either event, with or without dashing, we scale and stroke
            Canvas.scale {scaleX: 1.0, scaleY: (-1.0)} ctx
            Canvas.stroke ctx

        _ ->
            -- This is the case where we have an empty path, so there's nothing to do
            pure ctx


drawLine :: ∀ e. LineStyle -> Boolean -> List Point -> Context2D -> Eff (canvas :: Canvas | e) Context2D
drawLine style closed points =
    setStrokeStyle style >=> line style closed points


texture :: ∀ e. Context2D -> String -> (CanvasPattern -> Eff (canvas :: Canvas | e) Unit) -> Eff (canvas :: Canvas | e) Unit
texture ctx src redo =
    Canvas.withImage src \source ->
        Canvas.createPattern source Repeat ctx >>= redo


drawShape :: ∀ e. Context2D -> FillStyle -> Boolean -> List Point -> (CanvasPattern -> Eff (canvas :: Canvas | e) Unit) -> Eff (canvas :: Canvas | e) Context2D
drawShape ctx style closed points redo = do
    trace closed points ctx
    setFillStyle ctx style redo
    Canvas.scale {scaleX: 1.0, scaleY: (-1.0)} ctx
    Canvas.fill ctx


-- TEXT RENDERING

-- Returns true if setLineDash was available, false if not.
foreign import setLineDash :: ∀ e. List Int -> Context2D -> Eff (canvas :: Canvas | e) Boolean


fillText :: ∀ e. Text -> Context2D -> Eff (canvas :: Canvas | e) Context2D
fillText = drawCanvas Canvas.fillText


strokeText :: ∀ e. LineStyle -> Text -> Context2D -> Eff (canvas :: Canvas | e) Context2D
strokeText style t ctx = do
    setStrokeStyle style ctx

    when (style.dashing /= Nil) $ void $
        setLineDash (fromList style.dashing) ctx

    drawCanvas Canvas.strokeText t ctx


-- Should suggest adding this to Graphics.Canvas
foreign import globalAlpha :: ∀ e. Context2D -> Eff (canvas :: Canvas | e) Number


renderForm :: ∀ e. Context2D -> Form -> Eff (canvas :: Canvas | e) Unit -> Eff (canvas :: Canvas | e) Context2D
renderForm ctx (Form f) redo =
    Canvas.withContext ctx do
        when (f.x /= 0.0 || f.y /= 0.0) $ void $
            Canvas.translate
                { translateX: f.x
                , translateY: f.y
                }
                ctx

        when (f.theta /= 0.0) $ void $
            Canvas.rotate (f.theta `mod` (pi * 2.0)) ctx

        when (f.scale /= 1.0) $ void $
            Canvas.scale { scaleX: f.scale, scaleY: f.scale } ctx

        when (f.alpha /= 1.0) do
            ga <- globalAlpha ctx
            Canvas.setGlobalAlpha ctx (ga * f.alpha)
            pure unit

        Canvas.beginPath ctx

        case f.form of
            FPath style points ->
                drawLine style false points ctx

            FImage w h pos src -> do
                Canvas.withImage src \source -> do
                    Canvas.scale { scaleX: 1.0, scaleY: (-1.0) } ctx
                    Canvas.drawImageFull
                        ctx source
                        (toNumber pos.top) (toNumber pos.left)
                        (toNumber w) (toNumber h)
                        (toNumber (-w) / 2.0) (toNumber (-h) / 2.0)
                        (toNumber w) (toNumber h)
                    redo
                pure ctx

            FShape shapeStyle points ->
                case shapeStyle of
                    Line lineStyle ->
                        drawLine lineStyle true points ctx

                    Fill fillStyle ->
                        drawShape ctx fillStyle false points (const redo)

            FText t ->
                fillText t ctx

            FOutlinedText lineStyle t ->
                strokeText lineStyle t ctx

            _ ->
                -- There seem to be several unhandled cases in the original code ...
                pure ctx


formToMatrix :: Form -> Transform2D
formToMatrix (Form f) =
    let
        matrix =
            T2D.matrix f.scale 0.0 0.0 f.scale f.x f.y

    in
        if f.theta == 0.0
            then matrix
            else T2D.multiply matrix (T2D.rotation f.theta)


str :: Number -> String
str n =
    if n < 0.00001 && n > (-0.00001)
        then "0"
        else show n


{-
	function stepperHelp(list)
	{
		var arr = List.toArray(list);
		var i = 0;
		function peekNext()
		{
			return i < arr.length ? arr[i]._0.form.ctor : '';
		}
		// assumes that there is a next element
		function next()
		{
			var out = arr[i]._0;
			++i;
			return out;
		}
		return {
			peekNext: peekNext,
			next: next
		};
	}

	function formStepper(forms)
	{
		var ps = [stepperHelp(forms)];
		var matrices = [];
		var alphas = [];
		function peekNext()
		{
			var len = ps.length;
			var formType = '';
			for (var i = 0; i < len; ++i )
			{
				if (formType = ps[i].peekNext()) return formType;
			}
			return '';
		}
		// assumes that there is a next element
		function next(ctx)
		{
			while (!ps[0].peekNext())
			{
				ps.shift();
				matrices.pop();
				alphas.shift();
				if (ctx)
				{
					ctx.restore();
				}
			}
			var out = ps[0].next();
			var f = out.form;
			if (f.ctor === 'FGroup')
			{
				ps.unshift(stepperHelp(f._1));
				var m = A2(Transform.multiply, f._0, formToMatrix(out));
				ctx.save();
				ctx.transform(m[0], m[3], m[1], m[4], m[2], m[5]);
				matrices.push(m);

				var alpha = (alphas[0] || 1) * out.alpha;
				alphas.unshift(alpha);
				ctx.globalAlpha = alpha;
			}
			return out;
		}
		function transforms()
		{
			return matrices;
		}
		function alpha()
		{
			return alphas[0] || 1;
		}
		return {
			peekNext: peekNext,
			next: next,
			transforms: transforms,
			alpha: alpha
		};
	}
-}


-- There are a bunch of inter-related functions used in the `update` process that all want
-- some shared state. So, we'll define the functions in terms of a `StateT` that we'll call
-- `UpdateStateT`, where the state is an `UpdateState`.
--
-- In fact, some of this is read-only, so I suppose one ought to either combine StateT and
-- ReaderT, or use RWS, but I'll keep in simple for now.
--
-- I was having some trouble with the StateT stuff until I made this a newtype instead of a type
newtype UpdateState = UpdateState
    { w :: Number
    , h :: Number
    , div :: DOM.Element
    , kids :: NodeList
    , index :: Int
    , ratio :: Float
    }


type UpdateStateT m a = StateT UpdateState m a


evalUpdateT :: ∀ e m a. (MonadEff (dom :: DOM | e) m) => Number -> Number -> DOM.Element -> UpdateStateT m a -> m a
evalUpdateT w h div cb = do
    ratio <-
        liftEff $
            window >>= devicePixelRatio

    kids <-
        liftEff $
            childNodes (elementToNode div)

    let index = 0

    evalStateT cb $
        UpdateState
            { w, h, div, kids, index, ratio }


foreign import devicePixelRatio :: ∀ e. Window -> Eff (dom :: DOM | e) Number


makeCanvas :: ∀ e m. (MonadEff (dom :: DOM | e) m) => UpdateStateT m CanvasElement
makeCanvas = do
    canvas <-
        liftEff $
            createNode "canvas"

    liftEff do
        setStyle "display" "block" canvas
        setStyle "position" "absolute" canvas

    setCanvasProps canvas

    -- The unsafeCoerce should be fine, since we just created it and we know it's a canvas ...
    pure $
        unsafeCoerce canvas


setCanvasProps :: ∀ e m. (MonadEff (dom :: DOM | e) m) => DOM.Element -> UpdateStateT m DOM.Element
setCanvasProps canvas = do
    state <-
        gets \(UpdateState s) -> s

    liftEff do
        setStyle "width" ((show state.w) <> "px") canvas
        setStyle "height" ((show state.h) <> "px") canvas

        setAttribute "width" (show $ state.w * state.ratio) canvas
        setAttribute "height" (show $ state.h * state.ratio) canvas

    pure canvas


-- This unsafeCoerce should also be fine, since a CanvasElement must be a DOM.Element
canvasElementToElement :: CanvasElement -> DOM.Element
canvasElementToElement = unsafeCoerce


nodeToCanvasElement :: Node -> Maybe CanvasElement
nodeToCanvasElement node =
    case nodeName node of
        "CANVAS" ->
            Just $ unsafeCoerce node

        _ ->
            Nothing


transform :: ∀ e m. (MonadEff (canvas :: Canvas | e) m) => List Transform2D -> Context2D -> UpdateStateT m Context2D
transform transforms ctx = do
    state <-
        gets \(UpdateState s) -> s

    liftEff do
        Canvas.translate
            { translateX: state.w / 2.0 * state.ratio
            , translateY: state.h / 2.0 * state.ratio
            }
            ctx

        Canvas.scale
            { scaleX: state.ratio
            , scaleY: -state.ratio
            }
            ctx

        for_ transforms \m -> do
            -- It isn't clear in the Elm code where the corresponding `restore` will happen,
            -- or, indeed, what the point of saving each intermediate state is. So, once this
            -- is done, I should try deleting it and see what happens.
            Canvas.save ctx
            Canvas.transform m ctx

        pure ctx


currentChild :: ∀ e m. (MonadEff (dom :: DOM | e) m) => UpdateStateT m (Maybe Node)
currentChild = do
    state <-
        gets \(UpdateState s) -> s

    liftEff $
        toMaybe <$>
            item state.index state.kids


moveToNextChild :: ∀ m. (Monad m) => UpdateStateT m Unit
moveToNextChild =
    modify \(UpdateState s) ->
        UpdateState $
            s { index = s.index + 1 }


nextContext :: ∀ e m. (MonadEff (canvas :: Canvas, dom :: DOM | e) m) => List Transform2D -> UpdateStateT m Context2D
nextContext transforms = do
    state <-
        gets \(UpdateState s) -> s

    current <- currentChild

    case current of
        Just node ->
            case nodeToCanvasElement node of
                Just canvas -> do
                    -- We have a canvas, so we'll re-use it, and increment the index
                    -- so we're now pointing at the next thing.
                    moveToNextChild
                    setCanvasProps (canvasElementToElement canvas)
                    (liftEff $ Canvas.getContext2D canvas) >>= transform transforms

                Nothing -> do
                    -- Not a canvas, so remove it. And, we don't iterate the index,
                    -- since we've removed it, so it will already point to the next thing.
                    liftEff $ removeChild node (elementToNode state.div)

                    -- And we recurse. Should figure out how to use purescript-tailrec
                    nextContext transforms

        Nothing -> do
            -- We've run out of children. So, we make a new one, and increment
            -- the index to point *past* it.
            canvas <- makeCanvas

            ctx <- liftEff do
                appendChild (elementToNode (canvasElementToElement canvas)) (elementToNode state.div)
                Canvas.getContext2D canvas

            moveToNextChild

            transform transforms ctx


{-
makeTransform :: Number -> Number ->

	function makeTransform(w, h, form, matrices)
	{
		var props = form.form._0._0.props;
		var m = A6( Transform.matrix, 1, 0, 0, -1,
					(w - props.width ) / 2,
					(h - props.height) / 2 );
		var len = matrices.length;
		for (var i = 0; i < len; ++i)
		{
			m = A2( Transform.multiply, m, matrices[i] );
		}
		m = A2( Transform.multiply, m, formToMatrix(form) );

		return 'matrix(' +
			str( m[0]) + ', ' + str( m[3]) + ', ' +
			str(-m[1]) + ', ' + str(-m[4]) + ', ' +
			str( m[2]) + ', ' + str( m[5]) + ')';
	}

addElement ::
        function addElement(matrices, alpha, form)
		{
			var kid = kids[i];
			var elem = form.form._0;

			var node = (!kid || kid.getContext)
				? NativeElement.render(elem)
				: NativeElement.update(kid, kid.oldElement, elem);

			node.style.position = 'absolute';
			node.style.opacity = alpha * form.alpha * elem._0.props.opacity;
			NativeElement.addTransform(node.style, makeTransform(w, h, form, matrices));
			node.oldElement = elem;
			++i;
			if (!kid)
			{
				div.appendChild(node);
			}
			else
			{
				div.insertBefore(node, kid);
			}
		}
  -}

clearRest :: ∀ e m. (MonadEff (dom :: DOM | e) m) => UpdateStateT m Unit
clearRest = do
    child <- currentChild

    case child of
        Just c -> do
            state <-
                gets \(UpdateState s) -> s

            liftEff $
                removeChild c (elementToNode state.div)

            -- And recurse ... should investigate purescript-tailrec
            clearRest

        Nothing ->
            pure unit


{-
	function update(div, _, model)
	{
		var w = model.w;
		var h = model.h;

		var forms = formStepper(model.forms);
		var nodes = nodeStepper(w, h, div);
		var ctx = null;
		var formType = '';

		while (formType = forms.peekNext())
		{
			// make sure we have context if we need it
			if (ctx === null && formType !== 'FElement')
			{
				ctx = nodes.nextContext(forms.transforms());
				ctx.globalAlpha = forms.alpha();
			}

			var form = forms.next(ctx);
			// if it is FGroup, all updates are made within formStepper when next is called.
			if (formType === 'FElement')
			{
				// update or insert an element, get a new context
				nodes.addElement(forms.transforms(), forms.alpha(), form);
				ctx = null;
			}
			else if (formType !== 'FGroup')
			{
				renderForm(function() { update(div, model, model); }, ctx, form);
			}
		}
		nodes.clearRest();
		return div;
	}

-}
