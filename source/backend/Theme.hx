package backend;

import flixel.util.FlxSignal;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
/**
 * Every colors used in the app.
 */
@:publicFields
class Theme {
	public static var onThemeChanged:FlxSignal = new FlxSignal();

	static var fontPath:String = 'assets/data/musticapro.otf';

	// ui colors
	static var surface:FlxColor = 0xFF101010;
	static var border:FlxColor = 0xFF363636;
	static var container:FlxColor = 0xFF1B1B1B;
	static var containerHigh:FlxColor = 0xFF222222;
	static var onContainer:FlxColor = 0xFFDBDBDB;

	static var canvasCheckerLight:FlxColor = 0xFF2F2F2F;
	static var canvasCheckerDark:FlxColor = 0xFF262626;

	// elements colors
	static var buttonHover:FlxColor = 0xFF2A2A2A;
	static var buttonPressed:FlxColor = 0xFF3A3A3A;
	static var sliderFill:FlxColor = 0xFFFFFFFF;
	static var sliderBg:FlxColor = 0xFF303030;

	static var accent:FlxColor = 0xFF5A5A5A;
	static var disabled:FlxColor = 0xFF404040;
	static var disabledText:FlxColor = 0xFF666666;

	static var divider:FlxColor = 0xFF2A2A2A;
	static var overlay:FlxColor = 0x6C000000;

	static var textPrimary:FlxColor = 0xFFDBDBDB;
	static var textSecondary:FlxColor = 0xFF999999;
	static var textDisabled:FlxColor = 0xFF666666;
	// prop
	static var currentTheme:String = "dark";

	/**
	 * Returns all available theme names (defaults: dark, light).
	 * On desktop, it loads themes from assets/data/themes/ folder.
	 */
	static function getThemes():Array<String> {
		var themes:Array<String> = ["dark", "light"];

		#if sys
		var dir:String = "assets/data/themes/";
		if (FileSystem.exists(dir) && FileSystem.isDirectory(dir)) {
			for (file in FileSystem.readDirectory(dir)) {
				if (!file.endsWith(".json"))
					continue;
				var name:String = file.substr(0, file.length - 5);
				if (name != "dark" && name != "light")
					themes.push(name);
			}
		}
		#end

		return themes;
	}

	/**
	 * Load a theme by name.
	 * Falls back to dark theme if loading fails.
	 */
	static function loadTheme(name:String):Void {
		var json:Dynamic = null;
		var path:String = 'assets/data/themes/$name.json';

		if (name == "dark" || name == "light") {
			try {
				var raw:String = Assets.getText(path);
				if (raw != null)
					json = Json.parse(raw);
			} catch (e) {
				trace('failed to load theme "$name": $e');
			}
		}
		#if sys
		else {
			try {
				if (FileSystem.exists(path)) {
					json = Json.parse(File.getContent(path));
				} else {
					trace('theme file not found: $path');
				}
			} catch (e) {
				trace('failed to load theme "$name": $e');
			}
		}
		#else
		else {
			trace('custom colors isn\'t supported on this target, falling back to dark');
		}
		#end

		if (json == null) {
			trace('falling back to dark theme.');
			if (name != "dark")
				loadTheme("dark");
			return;
		}

		apply(json);
		currentTheme = name;
		trace('theme "$name" loaded.');

		onThemeChanged.dispatch();
	}

	static function apply(j:Dynamic):Void {
		inline function getColor(field:String, fallback:FlxColor):FlxColor {
			var v:Null<String> = Reflect.field(j, field);
			if (v == null)
				return fallback;
			return FlxColor.fromString(v);
		}
		
		inline function getString(field:String, fallback:String):String {
			var v:Null<String> = Reflect.field(j, field);
			if (v == null)
				return fallback;
			return v;
		}

		surface = getColor("surface", surface);
		border = getColor("border", border);
		container = getColor("container", container);
		containerHigh = getColor("containerHigh", containerHigh);
		onContainer = getColor("onContainer", onContainer);
		canvasCheckerLight = getColor("canvasCheckerLight", canvasCheckerLight);
		canvasCheckerDark = getColor("canvasCheckerDark", canvasCheckerDark);
		buttonHover = getColor("buttonHover", buttonHover);
		buttonPressed = getColor("buttonPressed", buttonPressed);
		sliderFill = getColor("sliderFill", sliderFill);
		sliderBg = getColor("sliderBg", sliderBg);
		accent = getColor("accent", accent);
		disabled = getColor("disabled", disabled);
		disabledText = getColor("disabledText", disabledText);
		divider = getColor("divider", divider);
		overlay = getColor("overlay", overlay);
		textPrimary = getColor("textPrimary", textPrimary);
		textSecondary = getColor("textSecondary", textSecondary);
		textDisabled = getColor("textDisabled", textDisabled);

		fontPath = getString('fontPath', fontPath);
	}
}
