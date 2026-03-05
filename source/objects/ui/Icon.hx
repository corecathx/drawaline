package objects.ui;

import flixel.FlxSprite;

class Icon extends FlxSprite {
	public function new(x:Float, y:Float, iconName:String) {
		super(x, y);

		loadGraphic('assets/images/icons.png', true, 32, 32);

		animation.add('brush', [0], 1, true);
		animation.add('eraser', [1], 1, true);
		animation.add('trash', [2], 1, true);
		animation.add('visibility', [3], 1, true);
		animation.add('visibility_off', [4], 1, true);
		animation.add('minimize', [5], 1, true);
		animation.add('maximize', [6], 1, true);
		animation.add('close', [7], 1, true);
		animation.add('camera_pan', [8], 1, true);

		animation.play(iconName);
	}
}
