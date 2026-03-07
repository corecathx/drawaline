package objects.ui;

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Toast extends RadiusSprite {
	public static var instance:Toast = null;

	public static function show(text:String) {
		if (instance == null) {
			trace("toast was never instantiated!");
			return;
		}

		instance._show(text);
	}

	public static var START_TIME:Int = 1;

	/**
	 * Defines how long toasts appear in seconds.
	 */
	public static var DECAY_TIME:Int = 5;

	public static var END_TIME:Int = 1;

	public var label:FlxText;
	public var timeBar:FlxSprite;

	var _yOffset:Int = 0;
	var _timer:Float = 0;
	var _tween:FlxTween;

	static final PADDING:Int = 5;
	static final RADIUS:Float = 10;

	public function new() {
		super(0, 0, 1, 1, RADIUS, Theme.containerHigh);
		instance = this;

		label = new FlxText();
		label.setFormat('assets/data/musticapro.otf', 12, FlxColor.WHITE, LEFT);

		timeBar = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);

		visible = false;
	}

	function _show(text:String) {
		trace('showing');
		_yOffset = 10;
		_timer = 0;
		alpha = 0;
		visible = true;
		label.text = text;

		if (_tween != null)
			_tween.cancel();

		_tween = FlxTween.tween(this, {_yOffset: 0, alpha: 1}, START_TIME, {
			ease: FlxEase.expoOut,
			onComplete: (_) -> {
				_tween = null;
			}
		});
	}

	function _hide() {
		trace('hiding');
		alpha = 1;
		visible = true;

		if (_tween != null)
			_tween.cancel();

		_tween = FlxTween.tween(this, {alpha: 0}, END_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: (_) -> {
				visible = false;
				_timer = 0;
				_tween = null;
			}
		});
	}

	override function draw() {
		var w:Float = label.width + PADDING * 2 + 4;
		var h:Float = label.height + PADDING * 2;

		resize(w, h);
		color = Theme.containerHigh;
		x = (FlxG.width - w) * 0.5;
		y = FlxG.height - (80 - _yOffset);

		super.draw();

		timeBar.scale.set(w * (_timer / DECAY_TIME), 2);
		timeBar.x = x + w * 0.5;
		timeBar.y = y + h - timeBar.scale.y;
		timeBar.alpha = alpha;
		timeBar.color = Theme.textSecondary;
		timeBar.cameras = cameras;
		timeBar.draw();

		label.x = x + (w - label.width) * 0.5;
		label.y = y + (h - label.height) * 0.5;
		label.alpha = alpha;
		label.color = Theme.textPrimary;
		label.cameras = cameras;
		label.draw();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (visible) {
			if (_timer < DECAY_TIME)
				_timer += elapsed;
			else if (_tween == null)
				_hide();
		}
	}
}
