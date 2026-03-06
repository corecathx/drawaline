package;

import backend.KeybindManager;
import backend.ProjectHandler;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.system.Clipboard;
import lime.utils.Assets;
import objects.Canvas;
import objects.Sidebar;
import objects.Toolbar;
import objects.ui.MenuBar;
import objects.ui.Popup;
import objects.ui.TextInput;

class PlayState extends FlxState {
	var hudCamera:FlxCamera;
	var canvas:Canvas;
	var sidebar:Sidebar;
	var toolbar:Toolbar;
	var menuBar:MenuBar;

	var zoom:Float = 1;

	static inline var ZOOM_MIN:Float = 0.2;
	static inline var ZOOM_MAX:Float = 4;
	static inline var ZOOM_STEP:Float = 0.1;

	public static var cameraPanningTool:Bool = false;
	public static var middleMousePanning:Bool = false;

	public static var lastMouseX:Float = 0;
	public static var lastMouseY:Float = 0;

	var infoTextBG:FlxSprite;
	var infoText:FlxText;
	var focusedLayerInfo:FlxText;

	var _lastTitle:String = "";

	override public function create() {
		super.create();
		FlxSprite.defaultAntialiasing = true;
		FlxG.camera.bgColor = Colors.surface;

		hudCamera = new FlxCamera();
		hudCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(hudCamera, false);

		canvas = new Canvas(640, 480);
		add(canvas);
		canvas.screenCenter();

		sidebar = new Sidebar(canvas, hudCamera);
		add(sidebar);

		toolbar = new Toolbar(canvas, hudCamera);
		add(toolbar);

		infoTextBG = new FlxSprite().makeGraphic(1, 30);
		infoTextBG.color = Colors.container;
		infoTextBG.cameras = [hudCamera];
		infoTextBG.origin.set(0, 0.5);
		add(infoTextBG);

		focusedLayerInfo = new FlxText(toolbar.toolbarWidth + 10, 32 + 10);
		focusedLayerInfo.setFormat('assets/data/musticapro.otf', 12, FlxColor.WHITE, LEFT);
		focusedLayerInfo.cameras = [hudCamera];
		add(focusedLayerInfo);

		initMenuBar();

		infoText = new FlxText();
		infoText.setFormat('assets/data/musticapro.otf', 12, FlxColor.WHITE, LEFT);
		infoText.cameras = [hudCamera];
		add(infoText);

		FlxG.camera.zoom = zoom;

		Main.instance.windowResized.add((w, h) -> hudCamera.setSize(w, h));

		var textInput = new TextInput();
		textInput.cameras = [hudCamera];
		add(textInput);

		ProjectHandler.newProject(canvas, () -> sidebar.layerList.rebuild());

		var keybinds:KeybindManager = new KeybindManager();
		keybinds.addKey([CONTROL, N], () -> ProjectHandler.newProject(canvas, _onProjectChange));
		keybinds.addKey([CONTROL, O], () -> canvas.loadProject(_onProjectChange, e -> trace("open error: " + e)));
		keybinds.addKey([CONTROL, S], () -> canvas.saveProject(_onProjectChange));
		keybinds.addKey([CONTROL, SHIFT, S], () -> ProjectHandler.saveAs(canvas, _onProjectChange));
		keybinds.addKey([CONTROL, E], () -> canvas.exportToPNG(() -> trace("export completed")));
		keybinds.addKey([CONTROL, V], _handlePaste);
		add(keybinds);
		Colors.onThemeChanged.add(updateColors);
	}

	function updateColors() {
		FlxG.camera.bgColor = Colors.surface;
		infoTextBG.color = Colors.container;
		infoText.color = Colors.textPrimary;
		focusedLayerInfo.color = Colors.textPrimary;
	}

	function _handlePaste() {
		trace(Clipboard.text);
	}

	function initMenuBar() {
		menuBar = new MenuBar(0, 0, FlxG.width);
		menuBar.cameras = [hudCamera];
		add(menuBar);

		var fileMenu = menuBar.addMenu("File", FlxG.width);
		fileMenu.addItem("New", () -> ProjectHandler.newProject(canvas, _onProjectChange));
		fileMenu.addItem("Open...", () -> canvas.loadProject(_onProjectChange, e -> trace("open error: " + e)));
		fileMenu.addItem("Save", () -> canvas.saveProject(_onProjectChange));
		fileMenu.addItem("Save As", () -> ProjectHandler.saveAs(canvas, _onProjectChange));
		fileMenu.addItem("Export PNG", () -> canvas.exportToPNG(() -> trace("export completed")));

		var editMenu = menuBar.addMenu("Edit", FlxG.width);
		editMenu.addItem("Undo", () -> canvas.focusedLayer?.undoLastStroke());
		editMenu.addItem("Redo", () -> trace("redo not implemented"));

		var viewMenu = menuBar.addMenu("View", FlxG.width);
		viewMenu.addItem("Toggle smoothing", () -> canvas.antialiasing = !canvas.antialiasing);

		var themeMenu = viewMenu.addSubmenu("Theme");
		for (theme in Colors.getThemes()) {
			themeMenu.addItem(theme, () -> Colors.loadTheme(theme));
		}
		
		var helpMenu = menuBar.addMenu("Help", FlxG.width);
		helpMenu.addItem("Controls", () -> Popup.show("Controls", Assets.getText('assets/data/menubar/controls.txt'), [
			{
				label: "OK",
				callback: () -> {}
			}
		]));
		helpMenu.addItem("About", () -> Popup.show("About", Assets.getText('assets/data/menubar/about.txt'), [{label: "OK", callback: () -> {}}]));
	}

	function _onProjectChange() {
		sidebar.layerList.rebuild();
		_updateTitleBar();
	}

	function _updateTitleBar() {
		var title = 'drawaline - ${canvas.projectFilePath ?? canvas.projectName}';
		if (title != _lastTitle) {
			_lastTitle = title;
			Application.current.window.title = title;
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var menuH = Std.int(menuBar.bg.scale.y);
		toolbar.toolbarYOffset = menuH;
		sidebar.sidebarYOffset = menuH;
		menuBar.bg.scale.x = FlxG.width;

		_updateInfoBar();
		_updateCanvasInteraction();
	}

	function _updateInfoBar() {
		var tbW = toolbar.toolbarWidth;
		var sbW = sidebar.sidebarWidth;

		infoTextBG.x = tbW;
		infoTextBG.y = FlxG.height - infoTextBG.height;
		infoTextBG.scale.x = FlxG.width - tbW - sbW;

		var mp = FlxG.mouse.getWorldPosition();
		var lx = Std.int(mp.x - canvas.x);
		var ly = Std.int(mp.y - canvas.y);
		var toolStr = getToolString();

		focusedLayerInfo.text = canvas.focusedLayer?.layerName ?? "No focused layer.";
		infoText.text = '${canvas.canvasWidth}x${canvas.canvasHeight} | $lx, $ly | ${Std.int(zoom * 100)}% | $toolStr';
		infoText.setPosition(infoTextBG.x + 5, infoTextBG.y + (infoTextBG.height - infoText.height) * 0.5);
	}

	function getToolString():String {
		if (middleMousePanning)
			return 'Camera Panning (Middle Mouse)';

		if (cameraPanningTool)
			return 'Camera Panning (Tool)';

		if (canvas.brushMode == DRAW)
			return 'Brush';
		if (canvas.brushMode == ERASE)
			return 'Eraser';

		return 'Unknown';
	}

	function _updateCanvasInteraction() {
		var mouseView = FlxG.mouse.getViewPosition(hudCamera);
		var menuH = menuBar.bg.scale.y;
		var blocked = mouseView.x > FlxG.width - sidebar.sidebarWidth || mouseView.y < menuH || mouseView.x < toolbar.toolbarWidth;

		if (canvas.focusedLayer != null)
			canvas.focusedLayer.active = !blocked;

		if (blocked)
			return;

		if (FlxG.mouse.wheel != 0 && FlxG.keys.pressed.CONTROL) {
			var oldZoom = zoom;
			zoom = Math.max(ZOOM_MIN, Math.min(ZOOM_MAX, zoom + FlxG.mouse.wheel * ZOOM_STEP));
			if (zoom != oldZoom) {
				var before = FlxG.mouse.getWorldPosition();
				FlxG.camera.zoom = zoom;
				var after = FlxG.mouse.getWorldPosition();
				FlxG.camera.scroll.x += before.x - after.x;
				FlxG.camera.scroll.y += before.y - after.y;
			}
		}

		var mv = FlxG.mouse.getViewPosition();

		if (FlxG.mouse.justPressedMiddle) {
			middleMousePanning = true;

			lastMouseX = mv.x;
			lastMouseY = mv.y;
		}

		if (FlxG.mouse.justPressed && cameraPanningTool) {
			lastMouseX = mv.x;
			lastMouseY = mv.y;
		}

		if (FlxG.mouse.pressedMiddle && middleMousePanning || FlxG.mouse.pressed && cameraPanningTool) {
			FlxG.camera.scroll.x -= mv.x - lastMouseX;
			FlxG.camera.scroll.y -= mv.y - lastMouseY;

			lastMouseX = mv.x;
			lastMouseY = mv.y;
		}

		if (FlxG.mouse.justReleasedMiddle)
			middleMousePanning = false;
	}
}
