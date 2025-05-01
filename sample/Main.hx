package sample;

import flatchart.format.CodenameFormat;
import flatchart.format.PsychFormat;
import flatchart.format.LegacyFormat;
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

function main() {
	FlatChart.init({
		onLog: (_, message, ?pos) -> haxe.Log.trace(message, pos),
		// logLevel: FlatChartLogLevel.DEBUG,
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat(), new PsychFormat(), new CodenameFormat()],
		readFileContents: true
	});

	Sys.println('');
	test('sample/bopeebo');
	Sys.println('');
	test('sample/guns');
	Sys.println('');
	test('sample/test');
	Sys.println('');
}

function test(path:String) {
	Sys.println('Detecting and wrapping format for $path...');
	final wrapper = FlatChart.detectAndWrapFormat(path);
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
