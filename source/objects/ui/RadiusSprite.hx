package objects.ui;

import flixel.addons.display.FlxSliceSprite;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class RadiusSprite extends FlxSliceSprite {
	public function new(x:Float, y:Float, w:Float, h:Float, radius:Float, color:FlxColor = FlxColor.WHITE) {
		var r:Int = Std.int(radius);
		var size:Int = r * 2 + 1;

		var src = new FlxSprite();
		src.makeGraphic(size, size, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRectComplex(src, 0, 0, size, size, radius, radius, radius, radius, FlxColor.WHITE);

		super(src.graphic, new FlxRect(r, r, 1, 1), w, h);

        this.color = color;
		setPosition(x, y);
		stretchLeft = stretchTop = stretchRight = stretchBottom = stretchCenter = true;

		src.destroy();
	}

    public function resize(w:Float, h:Float) {
        this.width = w;
        this.height = h;
    }
}