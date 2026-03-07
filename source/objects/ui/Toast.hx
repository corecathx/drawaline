package objects.ui;

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Toast extends FlxSprite {
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

    public function new() {
        super();
        makeGraphic(1,1);
        origin.set(0,0);
        instance = this;

		label = new FlxText();
		label.setFormat('assets/data/musticapro.otf', 12, FlxColor.WHITE, LEFT);
        visible = false;

        timeBar = new FlxSprite().makeGraphic(1,1);
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
        scale.set(label.width + 10, label.height + 10);
        x = (FlxG.width - scale.x) * 0.5;
        y = FlxG.height - (80 - _yOffset);
        color = Theme.containerHigh;

        super.draw();

        timeBar.scale.set(scale.x * (_timer / DECAY_TIME), 2);
        timeBar.x = x + (scale.x) * 0.5;
        timeBar.y = y + (scale.y - timeBar.scale.y);
        timeBar.alpha = alpha;
        timeBar.color = Theme.textSecondary;
		timeBar.cameras = cameras;
        timeBar.draw();

        label.x = x + (scale.x - label.width) * 0.5;
        label.y = y + (scale.y - label.height) * 0.5;
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