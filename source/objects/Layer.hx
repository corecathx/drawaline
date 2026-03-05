package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import lime.app.Application;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Layer extends FlxSprite {
	public static var nextID:Int = 0;

	public var layerID:Int;
	public var layerName:String;
	public var isFocused:Bool = false;

	var canvas:Canvas;
	var smoothX:Float = 0;
	var smoothY:Float = 0;
	var smoothing:Float = 0.3;
	var minDistance:Float = 0.5;

	var mouseBuffer:Array<{x:Float, y:Float}> = [];
	var isDrawing:Bool = false;
	var lastStrokePoint:{x:Float, y:Float};

	var history:Array<BitmapData> = [];
	var maxHistorySize:Int = 20;

	public function new(width:Int, height:Int, canvas:Canvas) {
		super();
		this.canvas = canvas;

		layerID = nextID++;
		layerName = 'Layer ${layerID + 1}';

		makeGraphic(width, height, FlxColor.TRANSPARENT, true);

		saveHistory();

		Application.current.window.onMouseMove.add(onRawMouseMove);
	}

	override function destroy() {
		Application.current.window.onMouseMove.remove(onRawMouseMove);

		for (bmp in history) {
			if (bmp != null)
				bmp.dispose();
		}

		super.destroy();
	}

	function onRawMouseMove(screenX:Float, screenY:Float) {
		if (isDrawing && FlxG.mouse.pressed) {
			var world:FlxPoint = FlxG.mouse.getWorldPosition(FlxG.camera);
			var localX:Float = world.x - canvas.x;
			var localY:Float = world.y - canvas.y;

			mouseBuffer.push({x: localX, y: localY});
		}
	}

	function saveHistory() {
		var copy = pixels.clone();
		history.push(copy);

		if (history.length > maxHistorySize) {
			var old = history.shift();
			if (old != null)
				old.dispose();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!isFocused)
			return;

		if (FlxG.mouse.justPressed)
			startStroke();

		if (FlxG.mouse.pressed && isDrawing)
			processBufferedPoints();

		if (FlxG.mouse.justReleased)
			endStroke();

		if (FlxG.keys.justPressed.DELETE)
			clearCanvas();

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
			undoLastStroke();
	}

	function startStroke() {
		isDrawing = true;

		var world:FlxPoint = FlxG.mouse.getWorldPosition();
		var localX:Float = world.x - canvas.x;
		var localY:Float = world.y - canvas.y;

		smoothX = localX;
		smoothY = localY;
		lastStrokePoint = {x: smoothX, y: smoothY};

		if (canvas.brushMode == ERASE)
			erase(smoothX, smoothY);

		if (canvas.brushMode == DRAW)
			FlxSpriteUtil.drawCircle(this, smoothX, smoothY, FlxMath.bound(canvas.brushSize / 2, 0.1, 200), canvas.brushColor);

		mouseBuffer = [];
	}

	function endStroke() {
		isDrawing = false;
		mouseBuffer = [];
		saveHistory();
	}

	function processBufferedPoints() {
		if (!FlxG.mouse.pressed || !isDrawing) {
			mouseBuffer = [];
			return;
		}

		if (mouseBuffer.length == 0) {
			var world:FlxPoint = FlxG.mouse.getWorldPosition();
			var targetX:Float = world.x - canvas.x;
			var targetY:Float = world.y - canvas.y;

			smoothX += (targetX - smoothX) * smoothing;
			smoothY += (targetY - smoothY) * smoothing;
			addPoint(smoothX, smoothY);
			return;
		}

		for (point in mouseBuffer) {
			smoothX += (point.x - smoothX) * smoothing;
			smoothY += (point.y - smoothY) * smoothing;

			addPoint(smoothX, smoothY);
		}

		mouseBuffer = [];
	}

	function addPoint(x:Float, y:Float) {
		var dx:Float = x - lastStrokePoint.x;
		var dy:Float = y - lastStrokePoint.y;

		var dist:Float = Math.sqrt(dx * dx + dy * dy);
		if (dist < minDistance)
			return;

		var stepSize:Float = 2.0;
		var steps:Int = Std.int(dist / stepSize);
		if (steps < 1)
			steps = 1;
		if (steps > 30)
			steps = 30;

		var prevX:Float = lastStrokePoint.x;
		var prevY:Float = lastStrokePoint.y;

		for (i in 1...steps + 1) {
			var t:Float = i / steps;

			var px:Float = lastStrokePoint.x + dx * t;
			var py:Float = lastStrokePoint.y + dy * t;

			if (canvas.brushMode == ERASE)
				erase(px, py);

			if (canvas.brushMode == DRAW)
				FlxSpriteUtil.drawLine(this, prevX, prevY, px, py, {color: canvas.brushColor, thickness: canvas.brushSize});

			prevX = px;
			prevY = py;
		}

		lastStrokePoint = {x: x, y: y};
	}

	function erase(x:Float, y:Float) {
		var radius = FlxMath.bound(canvas.brushSize / 2, 0.1, 200);
		var ix = Std.int(x);
		var iy = Std.int(y);
		var ir = Std.int(radius);

		pixels.lock();

		for (py in -ir...ir + 1) {
			for (px in -ir...ir + 1) {
				var dist = Math.sqrt(px * px + py * py);

				if (dist <= radius) {
					var px2 = ix + px;
					var py2 = iy + py;

					if (px2 >= 0 && px2 < width && py2 >= 0 && py2 < height) {
						pixels.setPixel32(px2, py2, 0x00000000);
					}
				}
			}
		}

		pixels.unlock();
		dirty = true;
	}

	public function undoLastStroke() {
		if (history.length <= 1)
			return;

		history.pop();
		var previousState = history[history.length - 1];

		if (previousState != null) {
			pixels.copyPixels(previousState, previousState.rect, new Point(0, 0));
			dirty = true;
		}
	}

	function clearCanvas() {
		pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
		dirty = true;
		saveHistory();
	}
}
