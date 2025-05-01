package chartdex.format;

import chartdex.Chartdex.ChartdexLogLevel;
import hxjsonast.Json.JsonValue;
import haxe.io.Path;
import chartdex.format.Format.FormatWrapper;
import hxjsonast.Parser;

using hxjsonast.Tools;
using StringTools;

class CodenameFormat extends Format {
	override function getName():String {
		return 'Codename Engine';
	}

	override function createWrapper():CodenameFormatWrapper {
		return new CodenameFormatWrapper(this);
	}

	override function isMatch(path:String):Bool {
		if (!Chartdex.config.fileSystem.directoryExists(path))
			return false;

		final filenames = Chartdex.config.fileSystem.readDirectory(path);
		Chartdex.log(ChartdexLogLevel.DEBUG, 'Filenames: ${filenames.join(', ')}');
		if (filenames.length == 0)
			return false;

		if (!filenames.contains('meta.json'))
			return false;

		if (Chartdex.config.readFileContents) {
			final filepath = Path.join([path, 'meta.json']);
			final text = Chartdex.config.fileSystem.getText(filepath);
			if (text == null)
				return false;

			final json = Parser.parse(text, filepath);

			if (json.getField('name') == null && json.getField('displayName') == null)
				return false;

			if (!filenames.contains('charts'))
				return false;

			final chartsPath = Path.join([path, 'charts']);
			final chartFiles = Chartdex.config.fileSystem.readDirectory(chartsPath);
			if (chartFiles == null)
				return false;

			for (filename in chartFiles) {
				if (!filename.endsWith('.json'))
					continue;

				final chartPath = Path.join([chartsPath, filename]);
				final chartText = Chartdex.config.fileSystem.getText(chartPath);
				if (chartText == null)
					continue;

				final chartJson = Parser.parse(chartText, chartPath);
				final codenameField = chartJson.getField('codenameChart');
				if (codenameField == null)
					return false;

				final codenameValue = codenameField.value.value;
				if (!codenameValue.match(JsonValue.JBool(true)))
					return false;
			}
		}

		return true;
	}

	// TODO: Implement print
}

class CodenameFormatWrapper extends FormatWrapper {
	public function new(format:CodenameFormat) {
		super(format);
	}

	override function load(path:String):CodenameFormatWrapper {
		if (!Chartdex.config.fileSystem.directoryExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, 'Directory not found: $path');
			return this;
		}

		final variations = _readVariations(path);
		Chartdex.log(ChartdexLogLevel.DEBUG, 'Found variations in $path: ${variations.join(', ')}');

		for (variation in variations)
			charts[variation] = _loadChart(path, variation);

		return this;
	}

	private function _readVariations(path:String):Array<String> {
		final chartsPath = Path.join([path, 'charts']);
		final files = Chartdex.config.fileSystem.readDirectory(chartsPath);
		if (files == null)
			return [];

		return files.filter(filename -> filename.endsWith('.json')).map(filename -> Path.withoutExtension(filename));
	}

	private function _loadChart(path:String, variation:String):Chart {
		final filepath = Path.join([path, 'charts', '$variation.json']);
		final text = Chartdex.config.fileSystem.getText(filepath);
		if (text == null) {
			Chartdex.log(ChartdexLogLevel.ERROR, 'Failed to read chart file: $filepath');
			return null;
		}

		final json:CodenameRaw = Parser.parse(text, filepath).getValue();

		json.meta ??= _loadCodenameMeta(path, variation);

		if (json.meta == null) {
			Chartdex.log(ChartdexLogLevel.ERROR, 'Failed to load meta data for $filepath');
			json.meta = {
				name: variation,
				bpm: 100,
				beatsPerMeasure: 4,
				stepsPerBeat: 4,
				needsVoices: false
			};
		}

		final result:Chart = {
			metadata: {
				title: json.meta.displayName ?? json.meta.name,
				artist: Chartdex.config.defaultArtist,
				album: Chartdex.config.defaultAlbum,
				charter: Chartdex.config.defaultCharter,
				bpmChanges: [
					{
						time: -1,
						bpm: json.meta.bpm ?? 100,
						beatsPerMeasure: json.meta.beatsPerMeasure ?? 4,
						stepsPerBeat: json.meta.stepsPerBeat ?? 4
					}
				],
			},
			tracks: [
				{
					sound: 'Inst',
					startTime: 0,
					endTime: 0
				}
			],
			strumlines: [],
			keyCount: 4,
			notes: [],
			events: [],
			stage: json.stage,
			extraValues: [
				CodenameExtraValue.ICON => json.meta.icon,
				CodenameExtraValue.COLOR => json.meta.color,
				CodenameExtraValue.COOP_ALLOWED => json.meta.coopAllowed,
				CodenameExtraValue.OPPONENT_MODE_ALLOWED => json.meta.opponentModeAllowed,
			]
		}

		if (json.meta.customValues != null) {
			for (field in Reflect.fields(json.meta.customValues)) {
				result.extraValues[field] = Reflect.field(json.meta.customValues, field);
			}
		}

		if (json.strumLines != null) {
			for (i => strumline in json.strumLines) {
				var trackIndex = 1;
				if (json.meta.needsVoices == true) {
					final voicesTrack = 'Voices${strumline.vocalsSuffix ?? ''}';
					trackIndex = Lambda.findIndex(result.tracks, track -> track.sound == voicesTrack);
					if (trackIndex == -1) {
						trackIndex = result.tracks.length;
						result.tracks.push({
							sound: voicesTrack,
							startTime: 0,
							endTime: 0
						});
					}
				}

				result.strumlines.push({
					position: [
						strumline.strumPos != null ? (strumline.strumPos[0] ?? strumline.strumLinePos ?? 0.25 + i * 0.5) : (strumline.strumLinePos ?? 0.25
							+ i * 0.5),
						strumline.strumPos != null ? (strumline.strumPos[1] ?? 50) : 50
					],
					scale: strumline.strumScale ?? 1,
					alpha: strumline.visible != null ? (strumline.visible ? 1 : 0) : 1,
					characters: strumline.characters,
					charactersPosition: ['dad', 'boyfriend', 'girlfriend'].indexOf(strumline.position),
					track: trackIndex,
					cpuControlled: strumline.type != 1
				});

				if (strumline.notes != null) {
					for (note in strumline.notes) {
						result.notes.push({
							time: note.time,
							sustain: note.sLen ?? 0,
							lane: i * result.keyCount + note.id,
							kind: note.type == 0 ? 'default' : json.noteTypes[note.type - 1]
						});
					}
				}
			}
		}

		if (json.events != null) {
			for (event in json.events) {
				switch (event.name) {
					case 'BPM Change':
						result.metadata.bpmChanges.push({
							time: event.time,
							bpm: event.params[0],
							beatsPerMeasure: json.meta.beatsPerMeasure ?? 4,
							stepsPerBeat: json.meta.stepsPerBeat ?? 4
						});
					case 'Camera Movement':
						result.events.push({
							time: event.time,
							kind: 'Move Camera',
							data: event.params
						});
					default:
						result.events.push({
							time: event.time,
							kind: event.name,
							data: event.params
						});
				}
			}
		}

		return result;
	}

	private function _loadCodenameMeta(path:String, variation:String):Null<CodenameRawMeta> {
		final filepaths = [Path.join([path, 'meta-$variation.json']), Path.join([path, 'meta.json'])];
		for (filepath in filepaths) {
			try {
				if (Chartdex.config.fileSystem.fileExists(filepath)) {
					final text = Chartdex.config.fileSystem.getText(filepath);
					if (text == null)
						continue;

					final json:CodenameRawMeta = Parser.parse(text, filepath).getValue();
					return json;
				}
			}
			catch (error) {
				Chartdex.log(ChartdexLogLevel.ERROR, 'Error parsing $filepath: $error');
			}
		}
		return null;
	}
}

typedef CodenameRaw = {
	@:optional var strumLines:Array<CodenameRawStrumline>;
	@:optional var events:Array<CodenameRawEvent>;
	@:optional var meta:CodenameRawMeta;
	var codenameChart:Bool;
	var stage:String;
	var scrollSpeed:Float;
	var noteTypes:Array<String>;
}

typedef CodenameRawMeta = {
	var name:String;
	@:optional var bpm:Float;
	@:optional var displayName:String;
	@:optional var beatsPerMeasure:Float;
	@:optional var stepsPerBeat:Float;
	@:optional var needsVoices:Bool;
	@:optional var icon:String;
	@:optional var color:Dynamic;
	@:optional var difficulties:Array<String>;
	@:optional var coopAllowed:Bool;
	@:optional var opponentModeAllowed:Bool;
	@:optional var customValues:Dynamic;
}

typedef CodenameRawStrumline = {
	var characters:Array<String>;
	var type:Int;
	var notes:Array<CodenameRawNote>;
	var position:String;
	@:optional var visible:Null<Bool>;
	@:optional var strumPos:Array<Float>;
	@:optional var strumScale:Float;
	@:optional var scrollSpeed:Float;
	@:optional var vocalsSuffix:String;

	@:optional var strumLinePos:Float;
}

typedef CodenameRawNote = {
	var time:Float;
	var id:Int;
	var type:Int;
	var sLen:Float;
}

typedef CodenameRawEvent = {
	var name:String;
	var time:Float;
	var params:Array<Dynamic>;
}

enum abstract CodenameExtraValue(String) from String to String {
	var ICON = 'icon';
	var COLOR = 'color';
	var COOP_ALLOWED = 'coopAllowed';
	var OPPONENT_MODE_ALLOWED = 'opponentModeAllowed';
}
