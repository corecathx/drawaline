package objects;

import backend.Colors;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.ui.Button;
import objects.ui.TextInput;
import openfl.geom.Matrix;

class LayerList extends FlxSpriteGroup {
	var canvas:Canvas;
	var layerItems:Array<LayerItem> = [];
	var itemContainer:FlxSpriteGroup;
	var bg:FlxSprite;

	public var pendingRebuild:Bool = false;

	var listWidth:Int;
	var listHeight:Int;

	static inline var ITEM_HEIGHT:Int = 40;
	static inline var ITEM_GAP:Int = 2;

	var scrollY:Float = 0;
	var maxScroll:Float = 0;

	public function new(x:Float, y:Float, width:Int, height:Int, canvas:Canvas) {
		super(x, y);
		this.canvas = canvas;
		listWidth = width;
		listHeight = height;

		bg = new FlxSprite().makeGraphic(width, height);
		bg.color = Colors.containerHigh;
		add(bg);

		itemContainer = new FlxSpriteGroup();
		add(itemContainer);
		Colors.onThemeChanged.add(updateColors);
	}

	function updateColors() {
		bg.color = Colors.containerHigh;
		rebuild();
	}
	public function rebuild() {
		for (item in layerItems) {
			itemContainer.remove(item, true);
			item.destroy();
		}
		layerItems = [];

		for (i in 0...canvas.layers.length) {
			var item = new LayerItem(2, i * (ITEM_HEIGHT + ITEM_GAP) + ITEM_GAP, listWidth - 4, ITEM_HEIGHT, canvas.layers[i], canvas, this);
			itemContainer.add(item);
			layerItems.push(item);
		}

		maxScroll = Math.max(0, layerItems.length * (ITEM_HEIGHT + ITEM_GAP) - listHeight);
		scrollY = Math.min(scrollY, maxScroll);
		_applyClip();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (pendingRebuild) {
			pendingRebuild = false;
			rebuild();
			return;
		}

		if (FlxG.mouse.overlaps(this, cameras[0]) && FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL) {
			scrollY = Math.max(0, Math.min(scrollY - FlxG.mouse.wheel * 20, maxScroll));
			_applyClip();
		}
	}

	function _applyClip() {
		itemContainer.y = y - scrollY;

		for (member in itemContainer.members) {
			if (member == null)
				continue;
			var sprite:FlxSprite = cast member;
			var itemY = sprite.y;
			var inView = !(itemY + ITEM_HEIGHT < y || itemY > y + listHeight);
			sprite.visible = inView;
			if (!inView)
				continue;

			var clipTop = Math.max(0, y - itemY);
			var clipBottom = Math.max(0, (itemY + ITEM_HEIGHT) - (y + listHeight));
			sprite.clipRect = (clipTop > 0 || clipBottom > 0) ? new FlxRect(0, clipTop, sprite.width, ITEM_HEIGHT - clipTop - clipBottom) : null;
		}
	}
}

class LayerItem extends FlxSpriteGroup {
	var layer:Layer;
	var canvas:Canvas;
	var parent:LayerList;

	var bg:FlxSprite;
	var focusIndicator:FlxSprite;
	var thumbnail:FlxSprite;
	var label:FlxText;
	var visibilityBtn:Button;
	var deleteBtn:Button;
	var upBtn:Button;
	var downBtn:Button;

	var itemWidth:Int;
	var itemHeight:Int;
	var thumbSize:Int;

	static inline var THUMB_REFRESH_INTERVAL:Float = 0.25;

	var thumbTimer:Float = 0;

	var _lastClickTime:Float = 0;

	static inline var DOUBLE_CLICK_TIME:Float = 0.3;

	public function new(x:Float, y:Float, width:Int, height:Int, layer:Layer, canvas:Canvas, parent:LayerList) {
		super(x, y);
		this.layer = layer;
		this.canvas = canvas;
		this.parent = parent;
		itemWidth = width;
		itemHeight = height;

		bg = new FlxSprite().makeGraphic(width, height, FlxColor.WHITE);
		add(bg);

		focusIndicator = new FlxSprite(0, 0).makeGraphic(3, height, Colors.accent);
		focusIndicator.visible = false;
		add(focusIndicator);

		thumbSize = height - 10;
		thumbnail = new FlxSprite(5, 5).makeGraphic(thumbSize, thumbSize, Colors.canvasCheckerDark, true);
		add(thumbnail);
		_refreshThumbnail();

		label = new FlxText(thumbnail.x + thumbSize + 5, 0, width - thumbSize - 82, layer.layerName);
		label.setFormat(FlxAssets.FONT_DEFAULT, 10, Colors.onContainer, LEFT);
		label.y = (height - label.height) / 2;
		add(label);

		var btnSize:Int = 13;
		var btnX:Int = width - 62;
		upBtn = new Button(btnX, Std.int(height / 2) - btnSize - 1, "^", btnSize, btnSize);
		downBtn = new Button(btnX, Std.int(height / 2) + 1, "v", btnSize, btnSize);
		visibilityBtn = new Button(width - 46, Std.int((height - 20) / 2), "", 20, 20, 'visibility');
		deleteBtn = new Button(width - 23, Std.int((height - 20) / 2), '', 20, 20, 'trash');
		add(upBtn);
		add(downBtn);
		add(visibilityBtn);
		add(deleteBtn);

		upBtn.onClick = () -> {
			if (canvas.reorderLayer(layer.layerID, -1))
				parent.pendingRebuild = true;
		};
		downBtn.onClick = () -> {
			if (canvas.reorderLayer(layer.layerID, 1))
				parent.pendingRebuild = true;
		};
		visibilityBtn.onClick = () -> {
			canvas.setLayerVisibility(layer.layerID, !layer.visible);
			visibilityBtn.setIcon(layer.visible ? "visibility" : "visibility_off");
		};
		deleteBtn.onClick = () -> {
			if (canvas.removeLayer(layer.layerID))
				parent.pendingRebuild = true;
		};
	}

	function _refreshThumbnail() {
		var src = canvas.getLayerPixels(layer.layerID);
		if (src == null)
			return;

		var m = new Matrix();
		m.scale(thumbSize / src.width, thumbSize / src.height);

		thumbnail.pixels.fillRect(thumbnail.pixels.rect, Colors.canvasCheckerDark);
		thumbnail.pixels.draw(src, m, null, null, null, true);
		thumbnail.dirty = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		thumbTimer += elapsed;
		if (thumbTimer >= THUMB_REFRESH_INTERVAL) {
			thumbTimer = 0;
			if (layer.dirty)
				_refreshThumbnail();
		}
		label.y = y + (height - label.height) / 2;
		var focused = layer.isFocused;
		focusIndicator.visible = focused;
		bg.color = focused ? Colors.buttonPressed : Colors.container;
		alpha = layer.visible ? 1.0 : 0.4;

		var cam = cameras[0];
		var overBtn = FlxG.mouse.overlaps(visibilityBtn, cam)
			|| FlxG.mouse.overlaps(deleteBtn, cam)
			|| FlxG.mouse.overlaps(upBtn, cam)
			|| FlxG.mouse.overlaps(downBtn, cam);

		if (FlxG.mouse.overlaps(bg, cam) && !overBtn) {
			if (!focused)
				bg.color = Colors.buttonHover;
			if (FlxG.mouse.justPressed) {
				canvas.setFocus(layer.layerID);

				var now:Float = haxe.Timer.stamp();
				if (now - _lastClickTime < DOUBLE_CLICK_TIME) {
					TextInput.show(x + (label.x - x), y + (label.y - y), Std.int(label.fieldWidth), Std.int(label.height), layer.layerName, (v) -> {
						layer.layerName = label.text = v.length > 0 ? v : layer.layerName;
					}, null);
				}
				_lastClickTime = now;
			}
		}
	}
}
