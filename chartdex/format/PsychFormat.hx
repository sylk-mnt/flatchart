package chartdex.format;

import hxjsonast.Json.JsonValue;
import chartdex.Chartdex.ChartdexLogLevel;
import haxe.io.Path;
import chartdex.format.Format.FormatWrapper;
import hxjsonast.Parser;

using hxjsonast.Tools;
using StringTools;

class PsychFormat extends Format {
	override function getName():String {
		return 'Psych Engine';
	}

	override function createWrapper():PsychFormatWrapper {
		return new PsychFormatWrapper(this);
	}

	override function isMatch(path:String):Bool {
		if (!Chartdex.config.fileSystem.directoryExists(path))
			return false;

		final filenames = Chartdex.config.fileSystem.readDirectory(path);
		if (filenames.length == 0)
			return false;

		final prefix = Path.withoutDirectory(path);
		final defaultFile = '$prefix.json';

		if (!filenames.contains(defaultFile)
			&& !Lambda.exists(filenames, filename -> filename.startsWith('$prefix-') && filename.endsWith('.json')))
			return false;

		if (Chartdex.config.readFileContents) {
			for (filename in filenames) {
				try {
					final filepath = Path.join([path, filename]);
					final json = Parser.parse(Chartdex.config.fileSystem.getText(filepath), filepath);

					if (json.getField('song') == null)
						return false;

					final song = json.getField('song').value;

					// TODO: Check events

					if (song.getField('song') == null || song.getField('bpm') == null || song.getField('notes') == null)
						return false;

					final sections = song.getField('notes').value;
					if (!sections.value.match(JsonValue.JArray(_)))
						return false;

					switch sections.value {
						case JsonValue.JArray(sections):
							for (section in sections) {
								if ((section.getField('sectionBeats') == null && section.getField('lengthInSteps') == null)
									|| section.getField('sectionNotes') == null
									|| section.getField('mustHitSection') == null)
									return false;
							}
						case _:
							return false;
					}
				}
				catch (error) {
					Chartdex.log(ChartdexLogLevel.ERROR, 'Error parsing $filename: $error');
					continue;
				}
			}

			Chartdex.log(ChartdexLogLevel.DEBUG, 'Found valid chart in $path');
		}

		return true;
	}

	// TODO: Implement print
}

class PsychFormatWrapper extends FormatWrapper {
	public function new(format:PsychFormat) {
		super(format);
	}

	override function load(path:String):PsychFormatWrapper {
		if (!Chartdex.config.fileSystem.directoryExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, 'Directory not found: $path');
			return this;
		}

		final variations = _readVariations(path);
		Chartdex.log(ChartdexLogLevel.DEBUG, 'Found variations in $path: ${variations.join(', ')}');

		for (variation in variations)
			charts[variation] = _loadChart(path, variation);

		// TODO: Load events

		return this;
	}

	private function _readVariations(path:String):Array<String> {
		final prefix = Path.withoutDirectory(path);

		return Chartdex.config.fileSystem.readDirectory(path)
			.filter(filename -> Chartdex.config.fileSystem.fileExists(Path.join([path, filename])))
			.map(filename -> {
				if (filename == '$prefix.json')
					return Chartdex.config.defaultVariation;
				else
					return Path.withoutExtension(filename.substr(prefix.length + 1));
			});
	}

	private function _loadChart(path:String, variation:String):Chart {
		final filepath = variation == Chartdex.config.defaultVariation ? Path.join([path, '${Path.withoutDirectory(path)}.json']) : Path.join([path, '${Path.withoutDirectory(path)}-$variation.json']);

		final json:PsychRaw = Parser.parse(Chartdex.config.fileSystem.getText(filepath), filepath).getField('song').value.getValue();

		final result:Chart = {
			metadata: {
				title: json.song,
				artist: json.artist ?? Chartdex.config.defaultArtist,
				album: Chartdex.config.defaultAlbum,
				charter: json.charter ?? Chartdex.config.defaultCharter,
				bpmChanges: [
					{
						time: -1,
						bpm: json.bpm,
						beatsPerMeasure: 4,
						stepsPerBeat: 4
					}
				],
			},
			tracks: [{sound: 'Inst', startTime: json.offset ?? 0, endTime: 0}],
			strumlines: [
				{
					position: [0.25, 50],
					scale: 1,
					alpha: 1,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: [json.player2],
					charactersPosition: 0,
					track: 1,
					cpuControlled: true
				},
				{
					position: [0.75, 50],
					scale: 1,
					alpha: 1,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: [json.player1],
					charactersPosition: 1,
					track: 1,
					cpuControlled: false
				},
				{
					position: [0.25, 50],
					scale: 1,
					alpha: 0,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: [json.gfVersion ?? json.player3 ?? 'gf'],
					charactersPosition: 2,
					track: 1,
					cpuControlled: true
				}
			],
			notes: [],
			events: [],
			stage: json.stage,
			extraValues: [
				PsychExtraValue.GAME_OVER_CHAR => json.gameOverChar,
				PsychExtraValue.GAME_OVER_SOUND => json.gameOverSound,
				PsychExtraValue.GAME_OVER_LOOP => json.gameOverLoop,
				PsychExtraValue.GAME_OVER_END => json.gameOverEnd,
				PsychExtraValue.DISABLE_NOTE_RGB => json.disableNoteRGB,
				PsychExtraValue.ARROW_SKIN => json.arrowSkin,
				PsychExtraValue.SPLASH_SKIN => json.splashSkin
			]
		}

		if (json.needsVoices)
			result.tracks.push({sound: 'Voices', startTime: json.offset ?? 0, endTime: 0});

		var currentBPM = json.bpm;
		var currentTime = 0.0;
		var lastMustHit = false;

		for (section in json.notes) {
			if (section.changeBPM && section.bpm != currentBPM) {
				currentBPM = section.bpm;
				result.metadata.bpmChanges.push({
					time: currentTime,
					bpm: currentBPM,
					beatsPerMeasure: section.sectionBeats != null ? section.sectionBeats : section.lengthInSteps * 0.25,
					stepsPerBeat: 4
				});
			}

			if (lastMustHit != section.mustHitSection) {
				lastMustHit = section.mustHitSection;
				result.events.push({
					time: currentTime,
					kind: 'Move Camera',
					data: [section.gfSection ? 2 : (section.mustHitSection ? 1 : 0)]
				});
			}

			for (note in section.sectionNotes) {
				var time:Float = note[0];
				var id:Int = note[1];
				var length:Float = note[2];

				var strumline = section.gfSection ? 2 : 0;
				if (section.mustHitSection)
					strumline = id >= 4 ? 0 : 1;
				else
					strumline = id >= 4 ? 1 : 0;

				id %= 4;

				result.notes.push({
					time: time,
					length: length,
					lane: id + 4 * strumline,
					kind: section.altAnim ? 'alt-anim' : null
				});
			}

			currentTime += section.sectionBeats != null ? section.sectionBeats * 60 / currentBPM * 1000 : section.lengthInSteps * 60 / currentBPM * 0.25 * 1000;
		}

		Chartdex.log(ChartdexLogLevel.DEBUG, 'Loaded chart from $filepath');
		return result;
	}
}

typedef PsychRaw = {
	@:optional var charter:Null<String>;
	@:optional var artist:Null<String>;
	var song:String;
	var notes:Array<PsychRawSection>;
	var events:Array<Array<Dynamic>>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	@:optional var offset:Null<Float>;

	var player1:String;
	var player2:String;
	@:optional var player3:Null<String>;
	@:optional var gfVersion:Null<String>;
	@:optional var stage:Null<String>;

	@:optional var gameOverChar:Null<String>;
	@:optional var gameOverSound:Null<String>;
	@:optional var gameOverLoop:Null<String>;
	@:optional var gameOverEnd:Null<String>;

	@:optional var disableNoteRGB:Null<Bool>;

	@:optional var arrowSkin:Null<String>;
	@:optional var splashSkin:Null<String>;
}

typedef PsychRawSection = {
	var sectionNotes:Array<Dynamic>;
	@:optional var sectionBeats:Null<Float>;
	@:optional var lengthInSteps:Null<Int>;
	var mustHitSection:Bool;
	@:optional var altAnim:Null<Bool>;
	@:optional var gfSection:Null<Bool>;
	@:optional var bpm:Null<Float>;
	@:optional var changeBPM:Null<Bool>;
}

enum abstract PsychExtraValue(String) from String to String {
	var GAME_OVER_CHAR = 'gameOverChar';
	var GAME_OVER_SOUND = 'gameOverSound';
	var GAME_OVER_LOOP = 'gameOverLoop';
	var GAME_OVER_END = 'gameOverEnd';
	var DISABLE_NOTE_RGB = 'disableNoteRGB';
	var ARROW_SKIN = 'arrowSkin';
	var SPLASH_SKIN = 'splashSkin';
}
