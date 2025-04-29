package chartdeck.fs;

import haxe.io.Bytes;
#if !flixel
import flatchart.FlatChart.FlatChartLogLevel;
class FlixelFileSystem implements IFileSystem {
	public function new() {
		FlatChart.log(FlatChartLogLevel.Error, 'Flixel required to use FlixelFileSystem');
	}

	public function readDirectory(path:String):Array<String> {
		return [];
	}

	public function getBytes(path:String):Null<Bytes> {
		return null;
	}

	public function directoryExists(path:String):Bool {
		return false;
	}

	public function fileExists(path:String):Bool {
		return false;
	}
}
#else
import openfl.Assets;
import flixel.FlxG;
import haxe.io.Path;

using StringTools;

class FlixelFileSystem implements IFileSystem {
	public function new() {}

	public function readDirectory(path:String):Array<String> {
		path = Path.addTrailingSlash(path);

		final assetIds = FlxG.assets.list().filter(assetId -> assetId.startsWith(path));

		final result:Array<String> = [];
		for (assetId in assetIds) {
			final trimmedPath = assetId.substring(path.length).split('/')[0];
			if (!result.contains(trimmedPath))
				result.push(trimmedPath);
		}
		return result;
	}

	public function getBytes(path:String):Null<Bytes> {
		if (!fileExists(path))
			return null;

		return FlxG.assets.getBytes(path);
	}

	public function directoryExists(path:String):Bool {
		path = Path.addTrailingSlash(path);
		#if sys
		path = Path.normalize(sys.FileSystem.absolutePath(path));
		#end

		return FlxG.assets.list().filter(assetId -> Assets.getPath(assetId).startsWith(path)).length > 0;
	}

	public function fileExists(path:String):Bool {
		return FlxG.assets.exists(path);
	}
}
#end
