package backend;

import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

typedef Keybind = {
	keys:Array<FlxKey>,
	callback:Void->Void
}

/**
 * An object to manage keybindings / shortcuts.
 */
class KeybindManager extends FlxBasic {
	public static var instance:KeybindManager = null;

	public var keybinds:Array<Keybind> = [];

	public function new() {
		super();
		instance = this;
	}

	/**
	 * Add a new key.
	 * @param keys Your key combinations.
	 * @param callback What to do when the key combo pressed.
	 */
	public function addKey(keys:Array<FlxKey>, callback:Void->Void) {
		keybinds.push({keys: keys, callback: callback});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (keybind in keybinds) {
			if (keybind.keys.length == 0)
				continue;

			var allModsHeld:Bool = true;

			for (i in 0...(keybind.keys.length - 1)) {
				if (!FlxG.keys.checkStatus(keybind.keys[i], PRESSED)) {
					allModsHeld = false;
					break;
				}
			}

			if (allModsHeld) {
				if (FlxG.keys.checkStatus(keybind.keys[keybind.keys.length - 1], JUST_PRESSED))
					keybind.callback();
			}
		}
	}
}
