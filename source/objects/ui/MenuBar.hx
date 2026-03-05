package objects.ui;

import backend.Colors;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class MenuItem extends FlxSpriteGroup {
	public var bg:FlxSprite;

	var label:FlxText;

	public var onClick:Void->Void = null;

	var isHovered:Bool = false;
	var itemWidth:Int;
	var itemHeight:Int;

	var parent:MenuDropdown;

	public function new(x:Float, y:Float, text:String, width:Int = 150, height:Int = 28, parent:MenuDropdown) {
		super(x, y);

		itemWidth = width;
		itemHeight = height;
		this.parent = parent;

		bg = new FlxSprite();
		bg.makeGraphic(width, height, FlxColor.WHITE);
		add(bg);

		label = new FlxText(8, 0, width - 16, text);
		label.setFormat(FlxAssets.FONT_DEFAULT, 11, Colors.onContainer, LEFT);
		label.y = (height - label.height) / 2;
		add(label);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		isHovered = FlxG.mouse.overlaps(bg, cameras[0]);

		if (isHovered) {
			bg.color = Colors.buttonHover;

			if (FlxG.mouse.justPressed && onClick != null) {
				onClick();
				parent.hide();
			}
		} else {
			bg.color = Colors.container;
		}
	}
}

class MenuDropdown extends FlxSpriteGroup {
	var bg:FlxSprite;

	public var items:Array<MenuItem> = [];

	var dropdownWidth:Int;
	var dropdownHeight:Int;

	public function new(x:Float, y:Float, width:Int = 150) {
		super(x, y);

		dropdownWidth = width;
		dropdownHeight = 0;

		bg = new FlxSprite();
		bg.makeGraphic(dropdownWidth, 1, Colors.container);
		bg.origin.set(0.5, 0);
		add(bg);

		hide();
	}

	public function addItem(text:String, onClick:Void->Void) {
		var itemY = dropdownHeight;
		var item = new MenuItem(0, itemY, text, dropdownWidth, 28, this);
		item.cameras = cameras;
		item.onClick = onClick;
		items.push(item);
		add(item);

		dropdownHeight += 28;
		bg.scale.y = dropdownHeight;

		return item;
	}

	public function show() {
		active = visible = true;
	}

	public function hide() {
		active = visible = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var mouseOverDropdown = false;
		for (item in items) {
			if (FlxG.mouse.overlaps(item.bg, cameras[0])) {
				mouseOverDropdown = true;
			}
		}

		if (FlxG.mouse.justPressed && !mouseOverDropdown) {
			hide();
		}
	}
}

class MenuBar extends FlxSpriteGroup {
	public var bg:FlxSprite;

	var menuButtons:Array<Button> = [];
	var dropdowns:Array<MenuDropdown> = [];
	var activeDropdown:MenuDropdown = null;

	public var barHeight:Int = 32;

	public function new(x:Float, y:Float, screenWidth:Int) {
		super(x, y);

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, Colors.container);
		bg.origin.set(0, 0);
		bg.scale.set(screenWidth, barHeight);
		add(bg);
	}

	public function addMenu(text:String, screenWidth:Int):MenuDropdown {
		var buttonX = (menuButtons.length * 65) + 8;
		var button = new Button(buttonX, 0, text, 60, barHeight);
		button.bgColorDefault = Colors.container;
		button.bgColorHovered = Colors.containerHigh;
		button.cameras = cameras;

		var dropdown = new MenuDropdown(buttonX, barHeight, 150);
		dropdown.cameras = cameras;
		button.onClick = function() {
			if (activeDropdown == dropdown) {
				dropdown.hide();
				activeDropdown = null;
			} else {
				if (activeDropdown != null) {
					activeDropdown.hide();
				}
				dropdown.show();
				activeDropdown = dropdown;
			}
		};

		menuButtons.push(button);
		dropdowns.push(dropdown);

		add(button);
		add(dropdown);

		return dropdown;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.mouse.justPressed && activeDropdown != null) {
			var clickedButton = false;
			for (btn in menuButtons) {
				if (FlxG.mouse.overlaps(btn.bg, cameras[0])) {
					clickedButton = true;
					break;
				}
			}

			if (!clickedButton && activeDropdown != null) {
				var clickedDropdown = false;
				for (item in activeDropdown.items) {
					if (FlxG.mouse.overlaps(item.bg, cameras[0])) {
						clickedDropdown = true;
						break;
					}
				}

				if (!clickedDropdown) {
					activeDropdown.hide();
					activeDropdown = null;
				}
			}
		}
	}
}
