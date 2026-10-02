package funkin.backend.system.framerate;

import funkin.backend.system.macros.GitCommitMacro;
import openfl.text.TextField;
import openfl.text.TextFormat;

class CodenameBuildField extends TextField {
	/** Versao da Prisma Engine mostrada no HUD. */
	public static inline var PRISMA_VERSION:String = "0.1.0";

	/** Credito exigido pela licenca da Codename Engine. Nao remova. */
	public static inline var CREDIT_LINE:String = "Based on Codename Engine";

	public function new() {
		super();
		autoSize = LEFT;
		multiline = wordWrap = false;
		reload();
	}

	public function reload() {
		defaultTextFormat = Framerate.textFormat;

		#if TEST_BUILD
		var title:String = 'Prisma Engine v${PRISMA_VERSION} (Test Build)';
		#elseif COMPILE_EXPERIMENTAL
		var title:String = 'Prisma Engine v${PRISMA_VERSION} (Experimental Build)';
		#else
		var title:String = 'Prisma Engine v${PRISMA_VERSION}';
		#end

		var creditStart:Int = title.length + 1;
		var full:String = '${title}\n${CREDIT_LINE}';

		#if (debug || COMPILE_EXPERIMENTAL)
		full += '\n${Flags.COMMIT_MESSAGE}';
		#end

		text = full;

		// linha de credito menor e mais discreta
		setTextFormat(new TextFormat(null, 10, 0xAAAAAA), creditStart, creditStart + CREDIT_LINE.length);
	}
}
