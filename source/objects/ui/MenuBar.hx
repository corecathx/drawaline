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

	public var label:FlxText;
	public var arrow:FlxText;

	public var onClick:Void->Void = null;
	public var submenu:MenuDropdown = null;

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

		label = new FlxText(8, 0, width - 24, text);
		label.setFormat(FlxAssets.FONT_DEFAULT, 11, Colors.onContainer, LEFT);
		label.y = (height - label.height) / 2;
		add(label);
		arrow = new FlxText(width - 16, 0, 12, ">");
		arrow.setFormat(FlxAssets.FONT_DEFAULT, 11, Colors.textSecondary, RIGHT);
		arrow.y = (height - arrow.height) / 2;
		arrow.visible = false;
		add(arrow);

		Colors.onThemeChanged.add(updateColors);
	}

	function updateColors() {
		label.color = Colors.textPrimary;
		arrow.color = Colors.textSecondary;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		isHovered = FlxG.mouse.overlaps(bg, cameras[0]);

		if (isHovered) {
			bg.color = Colors.buttonHover;

			if (submenu != null)
				parent.openSubmenu(this);

			if (FlxG.mouse.justPressed) {
				if (submenu == null && onClick != null) {
					onClick();
					parent.closeChain();
				}
			}
		} else {
			bg.color = (submenu != null && parent.activeItem == this) ? Colors.buttonPressed : Colors.container;
		}
	}
}

class MenuDropdown extends FlxSpriteGroup {
	var bg:FlxSprite;

	public var items:Array<MenuItem> = [];
	public var activeItem:MenuItem = null;
	public var parentDropdown:MenuDropdown = null;

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

	public function addItem(text:String, onClick:Void->Void):MenuItem {
		var item = _makeItem(text);
		item.onClick = onClick;
		return item;
	}

	public function addSubmenu(text:String, width:Int = 150):MenuDropdown {
		var item = _makeItem(text);
		item.arrow.visible = true;

		var sub = new MenuDropdown(0, 0, width);
		sub.parentDropdown = this;
		sub.cameras = cameras;
		item.submenu = sub;

		if (_onSubmenuCreated != null)
			_onSubmenuCreated(sub);

		return sub;
	}

	public dynamic function _onSubmenuCreated(sub:MenuDropdown):Void {}

	public function openSubmenu(item:MenuItem) {
		if (activeItem == item)
			return;

		if (activeItem != null)
			activeItem.submenu.hide();

		activeItem = item;

		var sub = item.submenu;
		sub.x = this.x + dropdownWidth;
		sub.y = this.y + (item.y - this.y);
		sub.show();
	}

	public function show() {
		active = visible = true;
		for (item in items)
			item.arrow.visible = item.submenu != null;
	}

	public function hide() {
		if (activeItem != null) {
			activeItem.submenu.hide();
			activeItem = null;
		}
		active = visible = false;
	}

	public function closeChain() {
		hide();
		if (parentDropdown != null)
			parentDropdown.closeChain();
	}

	function _makeItem(text:String):MenuItem {
		var item = new MenuItem(0, dropdownHeight, text, dropdownWidth, 28, this);
		item.cameras = cameras;
		items.push(item);
		add(item);

		dropdownHeight += 28;
		bg.scale.y = dropdownHeight;

		return item;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!FlxG.mouse.justPressed)
			return;

		var mouseOverSelf = false;
		for (item in items) {
			if (FlxG.mouse.overlaps(item.bg, cameras[0])) {
				mouseOverSelf = true;
				break;
			}
		}

		var mouseOverActiveSub = false;
		if (activeItem != null)
			mouseOverActiveSub = _overlapsSubmenuChain(activeItem.submenu);

		if (!mouseOverSelf && !mouseOverActiveSub)
			hide();
	}
	function _overlapsSubmenuChain(sub:MenuDropdown):Bool {
		if (sub == null || !sub.visible)
			return false;

		for (item in sub.items) {
			if (FlxG.mouse.overlaps(item.bg, cameras[0]))
				return true;
		}

		if (sub.activeItem != null)
			return _overlapsSubmenuChain(sub.activeItem.submenu);

		return false;
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
		bg.makeGraphic(1, 1);
		bg.color = Colors.container;
		bg.origin.set(0, 0);
		bg.scale.set(screenWidth, barHeight);
		add(bg);
		Colors.onThemeChanged.add(updateColors);
	}

	function updateColors() {
		bg.color = Colors.container;
		for (button in menuButtons) {
			button.bgColorDefault = Colors.container;
			button.bgColorHovered = Colors.containerHigh;
			button.bgColorPressed = Colors.buttonPressed;
		}
	}

	public function addMenu(text:String, screenWidth:Int):MenuDropdown {
		var buttonX = (menuButtons.length * 65) + 8;
		var button = new Button(buttonX, 0, text, 60, barHeight);
		button.bgColorDefault = Colors.container;
		button.bgColorHovered = Colors.containerHigh;
		button.bgColorPressed = Colors.buttonPressed;
		button.cameras = cameras;

		var dropdown = new MenuDropdown(buttonX, barHeight, 150);
		dropdown.cameras = cameras;
		dropdown._onSubmenuCreated = function(sub) {
			_registerSubmenu(sub);
		};

		button.onClick = function() {
			if (activeDropdown == dropdown) {
				dropdown.hide();
				activeDropdown = null;
			} else {
				if (activeDropdown != null)
					activeDropdown.hide();
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

	function _registerSubmenu(sub:MenuDropdown) {
		sub._onSubmenuCreated = function(child) {
			_registerSubmenu(child);
		};
		add(sub);
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

			if (!clickedButton) {
				activeDropdown.hide();
				activeDropdown = null;
			}
		}
	}
}