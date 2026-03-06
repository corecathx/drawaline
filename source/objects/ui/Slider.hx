package objects.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class Slider extends FlxSpriteGroup {
	var barBg:FlxSprite;
	var barFill:FlxSprite;
	var handle:FlxSprite;

	public var value(default, set):Float = 0;
	public var min:Float = 0;
	public var max:Float = 1;
	public var stepSize:Float = 0.01;
	public var onChanged:Float->Void = null;

	var moving:Bool = false;
	var barWidth:Int;
	var barHeight:Int;
	var isRainbow:Bool = false;

	public function new(x:Float, y:Float, width:Int = 200, height:Int = 5, ?initialValue:Float = 0.5) {
		super(x, y);

		this.barWidth = width;
		this.barHeight = height;
		this.value = initialValue;

		barBg = new FlxSprite();
		barBg.makeGraphic(width, height);
		add(barBg);

		barFill = new FlxSprite();
		barFill.makeGraphic(width, height);
		add(barFill);

		handle = new FlxSprite();
		handle.makeGraphic(2, height, FlxColor.WHITE);
		add(handle);

		updateColors();
		updateHandlePosition();
		Colors.onThemeChanged.add(updateColors);
	}

	function updateColors() {
		if (isRainbow)
			return;
		barBg.color = Colors.sliderBg;
		barFill.color = Colors.sliderFill;
	}

	// used in the editor sidebar
	public function makeRainbowGradient() {
		isRainbow = true;
		barFill.visible = false;
		barBg.color = FlxColor.WHITE;
		barBg.makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT);
		barBg.pixels.lock();

		for (px in 0...barWidth) {
			var hue:Float = (px / barWidth) * 360;
			var color:FlxColor = FlxColor.fromHSB(hue, 1.0, 1.0);

			for (py in 0...barHeight)
				barBg.pixels.setPixel32(px, py, color);
		}

		barBg.pixels.unlock();
		barBg.dirty = true;

		barBg.alpha = 0.6;
	}

	function set_value(val:Float):Float {
		var oldValue = value;
		value = Math.max(min, Math.min(val, max));

		if (oldValue != value && onChanged != null) {
			onChanged(value);
		}

		return value;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if ((FlxG.mouse.overlaps(barBg, cameras[0]) || FlxG.mouse.overlaps(handle, cameras[0])) && FlxG.mouse.justPressed) {
			moving = true;
		}

		if (moving && (FlxG.mouse.justMoved || FlxG.mouse.justPressed)) {
			var mouseX:Float = Math.max(x, Math.min(FlxG.mouse.getViewPosition(cameras[0]).x, x + barWidth));
			var normalized:Float = (mouseX - x) / barWidth;
			var rawValue:Float = min + normalized * (max - min);

			value = Math.round(rawValue / stepSize) * stepSize;
		}

		if (FlxG.mouse.justReleased) {
			moving = false;
		}

		updateHandlePosition();
	}

	function updateHandlePosition() {
		var normalized:Float = (value - min) / (max - min);

		barFill.scale.x = normalized;
		barFill.updateHitbox();

		handle.x = x + (normalized * barWidth) - (handle.width * 0.5);
		handle.y = y + (barHeight - handle.height) * 0.5;
	}
}
