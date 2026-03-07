package backend;

import flixel.util.FlxSignal;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
typedef ThemeEntry = {
	var id:String;
	var name:String;
}

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
	 * Returns all available themes.
	 * On desktop, it also loads themes from assets/data/themes/ folder.
	 */
	static function getThemes():Array<ThemeEntry> {
		var themes:Array<ThemeEntry> = [];

		var dir:String = "assets/data/themes/";
		for (file in Assets.list()) {
			if (!file.startsWith(dir) || !file.endsWith(".json"))
				continue;
			var id:String = file.substr(dir.length, file.length - dir.length - 5);
			themes.push({id: id, name: _readName(id)});
		}

		#if sys
		var dir:String = "assets/data/themes/";
		if (FileSystem.exists(dir) && FileSystem.isDirectory(dir)) {
			for (file in FileSystem.readDirectory(dir)) {
				if (!file.endsWith(".json"))
					continue;
				var id:String = file.substr(0, file.length - 5);
				if (themes.filter(e -> e.id == id).length > 0)
					continue;
				themes.push({id: id, name: _readName(id)});
			}
		}
		#end

		return themes;
	}

	/**
	 * Load a theme by id (file name without extension).
	 * Falls back to dark theme if loading fails.
	 */
	static function loadTheme(id:String):Void {
		var json:Dynamic = null;
		var path:String = 'assets/data/themes/$id.json';

		if (Assets.exists(path)) {
			try {
				var raw:String = Assets.getText(path);
				if (raw != null)
					json = Json.parse(raw);
			} catch (e) {
				trace('failed to load theme "$id": $e');
			}
		}
		#if sys
		else if (FileSystem.exists(path)) {
			try {
				json = Json.parse(File.getContent(path));
			} catch (e) {
				trace('failed to load theme "$id": $e');
			}
		}
		#end
		else {
		trace('theme "$id" not found');
	}

		if (json == null) {
			trace('falling back to dark theme.');
			if (id != "dark")
				loadTheme("dark");
			return;
		}

		apply(json);
		currentTheme = id;
		trace('theme "$id" loaded.');

		onThemeChanged.dispatch();
	}

	static function apply(j:Dynamic):Void {
		var colors:Dynamic = Reflect.field(j, "colors");

		inline function getColor(field:String, fallback:FlxColor):FlxColor {
			var v:Null<String> = Reflect.field(colors, field);
			if (v == null)
				return fallback;
			return FlxColor.fromString(v);
		}

		inline function getString(field:String, fallback:String):String {
			var v:Null<String> = Reflect.field(colors, field);
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

		fontPath = getString("fontPath", fontPath);
	}
	/**
	 * Reads just the "name" field from a theme json without fully loading it.
	 * Falls back to a prettified version of the id if no name is set.
	 */
	static function _readName(id:String):String {
		var path:String = 'assets/data/themes/$id.json';
		try {
			var raw:Null<String> = null;

			if (Assets.exists(path))
				raw = Assets.getText(path);
			#if sys
			else if (FileSystem.exists(path))
				raw = File.getContent(path);
			#end

			if (raw != null) {
				var json:Dynamic = Json.parse(raw);
				var n:Null<String> = Reflect.field(json, "name");
				if (n != null && n.trim() != "")
					return n;
			}
		} catch (e) {}

		return id.replace("-", " ")
			.replace("_", " ")
			.split(" ")
			.map(w -> w.charAt(0).toUpperCase() + w.substr(1))
			.join(" ");
	}
}