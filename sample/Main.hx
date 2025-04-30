package sample;

import flatchart.format.PsychFormat;
import flatchart.format.LegacyFormat;
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

function main() {
	FlatChart.init({
		onLog: (_, message, ?pos) -> haxe.Log.trace('FlatChart: $message', pos),
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat(), new PsychFormat()],
		highDetectionAccuracy: true
	});

	Sys.println('---');
	test('sample/bopeebo');
	Sys.println('---');
	test('sample/guns');
	Sys.println('---');
}

function test(path:String) {
	final wrapper = FlatChart.detectAndWrapFormat(path);
	if (wrapper != null) {
		trace(wrapper.format.getName());
		trace(wrapper.metadata.title);
		trace(wrapper.charts.map(chart -> chart.variation).join(', '));
	}
}
