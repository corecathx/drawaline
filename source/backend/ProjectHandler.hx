package backend;

import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import objects.Canvas;
import objects.Layer;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

typedef ProjectData = {
	var canvasWidth:Int;
	var canvasHeight:Int;
	var layers:Array<LayerData>;
}

typedef LayerData = {
	var pixelData:String;
	var visible:Bool;
	var layerName:String;
	var layerID:Int;
}

/**
 * A class that handles project related actions.
 */
class ProjectHandler {
	static var _fileRef:FileReference;

	/**
	 * Create a new project.
	 * @param canvas Canvas object
	 * @param onComplete Callback when creating is completed
	 */
	public static function newProject(canvas:Canvas, ?onComplete:Void->Void) {
		canvas.projectName = "Untitled";
		canvas.projectFilePath = null;
		canvas.removeAllLayers();
		Layer.nextID = 0;
		canvas.addLayer(true);
		if (onComplete != null)
			onComplete();
	}

	/**
	 * Export canvas contents to a PNG file.
	 * @param canvas Canvas object
	 * @param onComplete Callback when exporting is completed
	 */
	public static function exportToPNG(canvas:Canvas, ?onComplete:Void->Void) {
		var out:BitmapData = new BitmapData(canvas.canvasWidth, canvas.canvasHeight, true, 0x00000000);

		var reversed:Array<Layer> = canvas.layers.copy();
		reversed.reverse();
		for (l in reversed)
			if (l.visible)
				out.draw(l.pixels);

		var bytes:ByteArray = out.encode(out.rect, new PNGEncoderOptions());
		var d = Date.now();
		var name = 'drawing_${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}_${d.getHours()}-${d.getMinutes()}.png';

		_saveFile(bytes, name, onComplete);
	}

	/**
	 * Save project to .drw file.
	 * @param canvas Canvas object
	 * @param onComplete Callback when saving is completed
	 */
	public static function save(canvas:Canvas, ?onComplete:Void->Void) {
		if (canvas.projectFilePath == null) {
			saveAs(canvas, onComplete);
			return;
		}
		_performSave(canvas, onComplete);
	}

	/**
	 * Save project as a different .drw file.
	 * @param canvas Canvas object
	 * @param onComplete Callback when saving is completed
	 */
	public static function saveAs(canvas:Canvas, ?onComplete:Void->Void) {
		_fileRef = new FileReference();
		_fileRef.addEventListener(openfl.events.Event.SELECT, (_) -> {
			canvas.projectName = _fileRef.name.replace(".drw", "");
		});
		var bytes = _buildProjectBytes(canvas);
		_fileRef.save(bytes, '${canvas.projectName}.drw');
	}

	/**
	 * Load .drw projects.
	 * @param canvas Canvas object
	 * @param onComplete Callback when saving is completed
	 */
	public static function load(canvas:Canvas, ?onComplete:Void->Void, ?onError:String->Void) {
		_fileRef = new FileReference();
		_fileRef.addEventListener(openfl.events.Event.SELECT, (_) -> _fileRef.load());
		_fileRef.addEventListener(openfl.events.Event.COMPLETE, (_) -> {
			try {
				_applyProjectData(canvas, _fileRef.data.toString(), _fileRef.name);
				if (onComplete != null)
					onComplete();
			} catch (e:Dynamic) {
				trace('error loading project: $e');
				if (onError != null)
					onError('Failed to load project: $e');
			}
		});
		_fileRef.browse([new FileFilter("drawaline Project", "*.drw")]);
	}

	/// PRIVATE STUFFS ///

	static function _performSave(canvas:Canvas, ?onComplete:Void->Void) {
		var bytes:Bytes = _buildProjectBytes(canvas);
		_saveFile(bytes, '${canvas.projectName}.drw', onComplete);
	}

	static function _buildProjectBytes(canvas:Canvas):Bytes {
		var data:ProjectData = {
			canvasWidth: canvas.canvasWidth,
			canvasHeight: canvas.canvasHeight,
			layers: []
		};

		for (layer in canvas.layers) {
			data.layers.push({
				pixelData: _encodePixels(layer.pixels),
				visible: layer.visible,
				layerName: layer.layerName,
				layerID: layer.layerID
			});
		}

		return Bytes.ofString(Json.stringify(data, null, "  "));
	}

	/** BitmapData -> base64 string. */
	static function _encodePixels(bmp:BitmapData):String {
		var raw:ByteArray = new ByteArray();
		bmp.lock();
		for (y in 0...bmp.height)
			for (x in 0...bmp.width)
				raw.writeUnsignedInt(bmp.getPixel32(x, y));
		bmp.unlock();
		raw.position = 0;
		return Base64.encode(raw);
	}

	/** base64 string -> BitmapData pixels. */
	static function _decodePixels(encoded:String, bmp:BitmapData) {
		var decoded:Bytes = Base64.decode(encoded);
		var raw:ByteArray = new ByteArray();
		raw.writeBytes(decoded, 0, decoded.length);
		raw.position = 0;

		bmp.lock();
		for (y in 0...bmp.height)
			for (x in 0...bmp.width)
				bmp.setPixel32(x, y, raw.readUnsignedInt());
		bmp.unlock();
	}

	static function _applyProjectData(canvas:Canvas, json:String, filename:String) {
		var pd:ProjectData = Json.parse(json);
		canvas.removeAllLayers();
		Layer.nextID = 0;
		canvas.projectName = filename.replace(".drw", "");
		canvas.projectFilePath = filename;

		if (pd.canvasWidth != canvas.canvasWidth || pd.canvasHeight != canvas.canvasHeight) {
			canvas.canvasWidth = pd.canvasWidth;
			canvas.canvasHeight = pd.canvasHeight;
		}

		for (i in 0...pd.layers.length) {
			var ld = pd.layers[i];
			var layer:Layer = canvas.addLayer(i == 0);

			_decodePixels(ld.pixelData, layer.pixels);

			layer.visible = ld.visible;
			layer.layerName = ld.layerName;
			layer.layerID = ld.layerID;
			layer.dirty = true;
		}
	}

	static function _saveFile(data:Dynamic, name:String, ?onComplete:Void->Void) {
		_fileRef = new FileReference();
		_fileRef.addEventListener(openfl.events.Event.COMPLETE, (_) -> if (onComplete != null) onComplete());
		_fileRef.save(data, name);
	}
}
