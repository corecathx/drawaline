package objects.ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxInputText;

/**
 * Global singleton inline text input handler.
 * TODO: make it support multi line text editing.
 */
class TextInput extends FlxSpriteGroup {
	public static var instance:TextInput;

	var _input:FlxInputText;
	var _onConfirm:String->Void;
	var _onCancel:Void->Void;

	public function new() {
		super();
		instance = this;

		_input = new FlxInputText(0, 0, 120, "", 10);
		_input.backgroundColor = Colors.containerHigh;
		_input.fieldBorderThickness = 0;
		_input.color = Colors.textPrimary;
		_input.onEnter.add((text) -> {
			close(true);
		});
		add(_input);

		visible = false;
		active = false;
	}

	public static function show(x:Float, y:Float, w:Int, h:Int, text:String, onConfirm:String->Void, ?onCancel:Void->Void) {
		instance._open(x, y, w, h, text, onConfirm, onCancel);
	}

	function _open(x:Float, y:Float, w:Int, h:Int, text:String, onConfirm:String->Void, ?onCancel:Void->Void) {
		_onConfirm = onConfirm;
		_onCancel = onCancel;

		_input.cameras = cameras;
		setPosition(x, y);
		_input.setSize(w, h);
		_input.text = text;
		_input.startFocus();

		visible = true;
		active = true;

		trace('textinput opened');
	}

	function close(confirm:Bool) {
		visible = false;
		active = false;
		_input.endFocus();

		if (confirm) {
			if (_onConfirm != null)
				_onConfirm(_input.text);
		} else {
			if (_onCancel != null)
				_onCancel();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!visible)
			return;

		if (FlxG.keys.justPressed.ESCAPE)
			close(false);

		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(_input, cameras[0]))
			close(true);
	}
}
