package flatchart;

import haxe.PosInfos;
import flatchart.format.Format;
import flatchart.fs.IFileSystem;

@:structInit class FlatChartConfig {
	/**
	 * Default title for the chart. Used when no title is specified.
	 */
	public var defaultTitle:String = 'Untitled';

	/**
	 * Default artist name for the chart. Used when no artist is specified.
	 */
	public var defaultArtist:String = 'Unknown Artist';

	/**
	 * Default album name for the chart. Used when no album is specified.
	 */
	public var defaultAlbum:String = 'Unknown Album';

	/**
	 * Default charter name. Used when no charter is specified.
	 */
	public var defaultCharter:String = 'Unknown Charter';

	/**
	 * Default variation/difficulty name.
	 */
	public var defaultVariation:String = 'normal';

	/**
	 * Callback function for logging events.
	 * Takes a log level and message as parameters.
	 */
	public var onLog:(FlatChartLogLevel, String, ?PosInfos) -> Void = (_, _, ?_) -> {};

	/**
	 * Minimum log level to call the `onLog` callback.
	 */
	public var logLevel:FlatChartLogLevel = FlatChartLogLevel.Error;

	/**
	 * File system instance.
	 */
	public var fileSystem:IFileSystem;

	/**
	 * List of formats to use.
	 */
	public var formats:Array<Format> = [];
}

class FlatChart {
	public static var config:FlatChartConfig;

	public static function init(config:FlatChartConfig) {
		FlatChart.config = config;
	}

	public static function detectFormat(path:String):Null<Format> {
		for (format in config.formats) {
			if (format.isMatch(path))
				return format;
		}
		return null;
	}

	public static function wrapFormat(path:String, format:Format):FormatWrapper {
		return format.createWrapper().load(path);
	}

	public static function detectAndWrapFormat(path:String):FormatWrapper {
		final format = detectFormat(path);
		if (format == null) {
			FlatChart.log(FlatChartLogLevel.Error, 'Format not found for $path');
			return null;
		}

		return wrapFormat(path, format);
	}

	public static function log(level:FlatChartLogLevel, message:String, ?pos:PosInfos) {
		if ((level : Int) <= (config.logLevel : Int))
			return;

		if (config.onLog != null)
			config.onLog(level, message);
	}
}

enum abstract FlatChartLogLevel(Int) to Int {
	var Debug = 0;
	var Info = 1;
	var Warn = 2;
	var Error = 3;
}
