package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.system.scaleModes.EditorScaleMode;
import flixel.util.FlxSignal;
import lime.app.Application;
import openfl.display.Sprite;
#if html5
import js.Browser;
#end

class Main extends Sprite {
	public static var instance:Main = null;

	public var windowResized:FlxTypedSignal<Int->Int->Void>;

	public function new() {
		super();
		instance = this;
		windowResized = new FlxTypedSignal();
		FlxAssets.FONT_DEFAULT = 'assets/data/musticapro.otf';
		addChild(new FlxGame(0, 0, PlayState, 60, 60, true));

		FlxG.autoPause = false;
		FlxG.scaleMode = new EditorScaleMode();
		FlxG.signals.gameResized.add(_onWindowResize);

		#if html5
		Browser.window.onresize = function(_) {
			trace("browser resized: " + Browser.window.innerWidth + "x" + Browser.window.innerHeight);
			_onWindowResize(Browser.window.innerWidth, Browser.window.innerHeight);
		};
		#end
	}

	function _onWindowResize(nWidth:Int, nHeight:Int) {
		FlxG.resizeGame(nWidth, nHeight);
		windowResized.dispatch(nWidth, nHeight);
	}
}
