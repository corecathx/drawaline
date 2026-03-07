package objects.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

typedef PopupButton = {
	var label:String;
	var ?icon:String;
	var ?color:FlxColor;
	var ?textColor:FlxColor;
	var callback:Void->Void;
}

class Popup extends FlxSubState {
	static inline var W:Int = 320;
	static inline var PAD:Int = 20;
	static inline var BTN_H:Int = 30;
	static inline var BTN_GAP:Int = 8;

	public static function show(title:String, message:String, buttons:Array<PopupButton>) {
		FlxG.state.openSubState(new Popup(title, message, buttons));
	}

	function new(title:String, message:String, buttons:Array<PopupButton>) {
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var bx = (FlxG.width - W) / 2;

		var titleText = new FlxText(0, 0, W - PAD * 2, title);
		titleText.setFormat(FlxAssets.FONT_DEFAULT, 18, Theme.textPrimary, LEFT);

		var msgText = new FlxText(0, 0, W - PAD * 2, message);
		msgText.setFormat(FlxAssets.FONT_DEFAULT, 12, Theme.textSecondary, LEFT);

		var contentHeight = PAD + titleText.height + 2 + msgText.height + 16;

		var buttonAreaHeight = 0;
		if (buttons.length > 0) {
			buttonAreaHeight = BTN_H;
		}

		var boxH = contentHeight + buttonAreaHeight + PAD;

		var by = (FlxG.height - boxH) / 2;

		var overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, Theme.overlay);
		add(overlay);

		var box = new FlxSprite(bx, by);
		box.makeGraphic(W, Std.int(boxH), Theme.surface);
		add(box);

		titleText.x = bx + PAD;
		titleText.y = by + PAD;
		add(titleText);

		msgText.x = bx + PAD;
		msgText.y = titleText.y + titleText.height + 2;
		add(msgText);

		if (buttons.length > 0) {
			var btnY = by + boxH - PAD - BTN_H;
			var btnX = bx + W - PAD;

			for (i in 0...buttons.length) {
				var def = buttons[buttons.length - 1 - i];
				var btn = new Button(0, btnY, def.label, 90, BTN_H, def.icon);
				btn.cameras = cameras;

				if (def.color != null)
					btn.bgColorDefault = def.color;
				if (def.textColor != null)
					btn.label.color = def.textColor;

				var cb = def.callback;
				btn.onClick = () -> {
					close();
					cb();
				};

				btnX -= btn.width;
				btn.x = btnX;
				btnX -= BTN_GAP;

				add(btn);
			}
		}
	}
}
