package flixel.system.scaleModes;

import flixel.FlxG;

class EditorScaleMode extends BaseScaleMode {
	override public function onMeasure(Width:Int, Height:Int):Void {
		FlxG.width = Width;
		FlxG.height = Height;

		scale.set(1, 1);
		FlxG.game.x = 0;
		FlxG.game.y = 0;

		if (FlxG.camera != null) {
			FlxG.camera.setSize(Width, Height);
		}
	}
}
