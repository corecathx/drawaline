package objects.ui;

import backend.Colors;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Button extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var label:FlxText;
	public var icon:Icon;

	public var onClick:Void->Void = null;
	public var enabled:Bool = true;
	public var bgColorDefault:FlxColor = Colors.containerHigh;
	public var bgColorHovered:FlxColor = Colors.buttonHover;
	public var bgColorPressed:FlxColor = Colors.buttonPressed;
	public var bgColorDisabled:FlxColor = Colors.disabled;
	public var labelColorDisabled:FlxColor = Colors.textDisabled;

	var isHovered:Bool = false;
	var isPressed:Bool = false;

	var buttonWidth:Int;
	var buttonHeight:Int;

	public function new(x:Float, y:Float, text:String = '', width:Int = 100, height:Int = 30, ?iconName:String) {
		super(x, y);

		buttonWidth = width;
		buttonHeight = height;

		bg = new FlxSprite();
		bg.makeGraphic(width, height, FlxColor.WHITE);
		add(bg);

		if (iconName != null) {
			icon = new Icon(0, 0, iconName);
			var iconPadding:Int = 2;
			var maxSize:Float = Math.min(width, height) - iconPadding * 2;
			if (icon.width > maxSize || icon.height > maxSize) {
				var scale:Float = maxSize / Math.max(icon.width, icon.height);
				icon.scale.set(scale, scale);
				icon.updateHitbox();
			}
			add(icon);
		}

		if (text != '') {
			label = new FlxText(0, 0, width, text);
			label.setFormat(FlxAssets.FONT_DEFAULT, 12, Colors.onContainer, CENTER);
			label.y = (height - label.height) / 2;

			if (icon != null) {
				var padding:Float = 2;
				icon.x = padding;
				label.x = icon.x + icon.width + padding;
				label.fieldWidth = width - Std.int(label.x);
			}

			add(label);
		} else if (icon != null) {
			icon.x = x + (width - icon.width) * 0.5;
			icon.y = y + (height - icon.height) * 0.5;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!enabled) {
			bg.color = bgColorDisabled;
			if (label != null)
				label.color = labelColorDisabled;
			if (icon != null)
				icon.color = labelColorDisabled;
			return;
		}

		if (label != null)
			label.color = Colors.textPrimary;
		if (icon != null)
			icon.color = Colors.textPrimary;

		isHovered = FlxG.mouse.overlaps(bg, cameras[0]);

		if (isHovered && FlxG.mouse.justPressed)
			isPressed = true;

		if (isPressed && FlxG.mouse.justReleased) {
			if (isHovered && onClick != null)
				onClick();
			isPressed = false;
		}

		if (isPressed)
			bg.color = bgColorPressed;
		else if (isHovered)
			bg.color = bgColorHovered;
		else
			bg.color = bgColorDefault;
	}

	public function setText(text:String) {
		if (label != null)
			label.text = text;
	}

	public function setIcon(iconName:String) {
		if (icon != null)
			icon.animation.play(iconName);
	}
}
