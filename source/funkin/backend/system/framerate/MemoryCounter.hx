package funkin.backend.system.framerate;

import openfl.display.Sprite;
import openfl.text.TextField;

/**
 * Prisma Engine - contador de RAM e CPU.
 *
 *   RAM: <consumo do jogo> / <RAM total do aparelho>
 *   CPU: <uso do processo>%
 */
class MemoryCounter extends Sprite {
	public var memoryText:TextField; // "RAM: 512 MB"
	public var memoryPeakText:TextField; // " / 7.4 GB" (RAM total do aparelho)
	public var cpuText:TextField; // "CPU: 12%"

	public var memory:Float = 0; // consumo do jogo (bytes)
	public var memoryPeak:Float = 0; // RAM total do aparelho (bytes)
	public var cpu:Float = -1; // uso de CPU (%)

	public function new() {
		super();

		memoryText = new TextField();
		memoryPeakText = new TextField();
		cpuText = new TextField();

		for(label in [memoryText, memoryPeakText, cpuText]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "MEM";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = Framerate.textFormat;
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;

		cpuText.text = "CPU";
		cpuText.y = memoryText.height;
	}

	public function reload() {
		for(label in [memoryText, memoryPeakText, cpuText]) label.defaultTextFormat = Framerate.textFormat;
		cpuText.y = memoryText.height;
	}

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		PrismaStats.update(t / 1000);

		#if (cpp && (windows || mac || linux))
		final game:Float = MemoryUtil.currentProcessMemUsage();
		#else
		final game:Float = PrismaStats.gameRam;
		#end
		final total:Float = PrismaStats.deviceRam;
		final cpuNow:Float = Math.round(PrismaStats.cpuPercent);

		if (game != memory || total != memoryPeak) {
			memory = game;
			memoryPeak = total;
			memoryText.text = 'RAM: ${PrismaStats.format(game)}';
			memoryPeakText.text = ' / ${PrismaStats.format(total)}';
		}

		if (cpuNow != cpu) {
			cpu = cpuNow;
			cpuText.text = 'CPU: ${Std.int(cpuNow)}%';
		}

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
		memoryPeakText.x = memoryText.x + memoryText.width;
}
