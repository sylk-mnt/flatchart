package sample;

import chartdex.format.CodenameFormat;
import chartdex.format.PsychFormat;
import chartdex.format.LegacyFormat;
import chartdex.fs.SysFileSystem;
import chartdex.Chartdex;

function main() {
	Chartdex.config = {
		onLog: (_, message, ?pos) -> haxe.Log.trace(message, pos),
		// logLevel: ChartdexLogLevel.DEBUG,
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat(), new PsychFormat(), new CodenameFormat()],
		readFileContents: true
	}

	Sys.println('');
	Sys.println('Chartdex testing sample charts...');
	Sys.println('');
	test('sample/bopeebo');
	Sys.println('');
	test('sample/guns');
	Sys.println('');
	test('sample/test');
	Sys.println('');
}

function test(path:String) {
	try {
		Sys.println('Detecting and wrapping format for $path...');
		final wrapper = Chartdex.detectAndWrapFormat(path);
		if (wrapper == null) {
			Sys.println('No format detected for $path!');
		} else {
			Sys.println('Format ${wrapper.format.getName()} detected and wrapped for $path!');

			Sys.println('\tVariations: ${wrapper.charts.map(chart -> chart.variation).join(', ')}');
			for (chart in wrapper.charts) {
				Sys.println('\t\t${chart.variation}:');
				Sys.println('\t\t\tTitle: ${chart.metadata.title}');
				Sys.println('\t\t\tArtist: ${chart.metadata.artist}');
				Sys.println('\t\t\tAlbum: ${chart.metadata.album}');
				Sys.println('\t\t\tBPM: ${chart.metadata.bpmChanges[0].bpm}');
				Sys.println('\t\t\tTime signature: ${chart.metadata.bpmChanges[0].beatsPerMeasure}/${chart.metadata.bpmChanges[0].stepsPerBeat}');
				Sys.println('\t\t\tNotes: ${chart.notes.length}');
				Sys.println('\t\t\tEvents: ${chart.events.length}');
			}
		}
	}
	catch (error) {
		Sys.println('Error: $error');
	}
}
