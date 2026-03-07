package objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.ui.RadiusSprite;

class Eyedropper extends FlxSpriteGroup {
	public var selectedColor:FlxColor = FlxColor.WHITE;
	public var onColorChanged:FlxColor->Void = null;

	var preview:RadiusSprite;
	var previewBorder:RadiusSprite;
	var hexLabel:FlxText;
	var tooltip:RadiusSprite;

	static final PREVIEW_SIZE:Int = 24;
	static final RADIUS:Float = 10;
	static final OFFSET_X:Int = 16;
	static final OFFSET_Y:Int = 20;

	public function new() {
		super();
		tooltip = new RadiusSprite(0, 0, PREVIEW_SIZE + 80, PREVIEW_SIZE + 8, RADIUS, Theme.containerHigh);
		add(tooltip);
		previewBorder = new RadiusSprite(0, 0, PREVIEW_SIZE + 4, PREVIEW_SIZE + 4, RADIUS, Theme.border);
		add(previewBorder);
		preview = new RadiusSprite(0, 0, PREVIEW_SIZE, PREVIEW_SIZE, RADIUS, FlxColor.WHITE);
		add(preview);
		hexLabel = new FlxText(0, 0, 0, "#FFFFFF", 10);
		hexLabel.setFormat(FlxAssets.FONT_DEFAULT, 10, Theme.textPrimary, LEFT);
		add(hexLabel);
	}

	var pixel:FlxColor = FlxColor.WHITE;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!visible)
			return;

		var mx:Int = Std.int(FlxG.mouse.getViewPosition(cameras[0]).x);
		var my:Int = Std.int(FlxG.mouse.getViewPosition(cameras[0]).y);

		if (FlxG.stage != null && FlxG.mouse.justMoved) {
			var bd = FlxG.stage.window.readPixels();
			if (bd != null) {
				var px:Int = Std.int(Math.max(0, Math.min(mx-1, bd.width - 1)));
				var py:Int = Std.int(Math.max(0, Math.min(my-1, bd.height - 1)));
				// readPixels() returns RGBA, FlxColor expects ARGB, we swap them
				var rgba:Int = bd.getPixel32(px, py);
				var r:Int = (rgba >> 24) & 0xFF;
				var g:Int = (rgba >> 16) & 0xFF;
				var b:Int = (rgba >> 8)  & 0xFF;
				var a:Int =  rgba        & 0xFF;
				pixel = (a << 24) | (r << 16) | (g << 8) | b;
			}
		}

		selectedColor = pixel;
		hexLabel.text = '#${pixel.toHexString(false, false).toUpperCase()}';

		preview.color = pixel;
		previewBorder.color = Theme.border;
		tooltip.color = Theme.containerHigh;
		hexLabel.color = Theme.textPrimary;

		var tx:Float = mx + OFFSET_X;
		var ty:Float = my + OFFSET_Y;
		if (tx + tooltip.width > FlxG.width)
			tx = mx - tooltip.width - 4;
		if (ty + tooltip.height > FlxG.height)
			ty = my - tooltip.height - 4;

		tooltip.setPosition(tx, ty);

		var padding:Int = 4;
		previewBorder.setPosition(tx + padding - 2, ty + padding - 2);
		preview.setPosition(tx + padding, ty + padding);
		hexLabel.setPosition(tx + padding + PREVIEW_SIZE + 6, ty + padding + (PREVIEW_SIZE - hexLabel.height) * 0.5);

		if (FlxG.mouse.justPressed) {
			if (onColorChanged != null)
				onColorChanged(selectedColor);
			visible = false;
		}

		if (FlxG.mouse.justPressedRight)
			visible = false;
	}
}