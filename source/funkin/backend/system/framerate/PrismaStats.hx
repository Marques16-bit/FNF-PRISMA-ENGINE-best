package funkin.backend.system.framerate;

import haxe.Timer;
import openfl.system.System;

/**
 * Prisma Engine - leituras de RAM e CPU para o FPS HUD.
 *
 * Haxe puro nao expoe a RAM total do aparelho nem o uso de CPU, entao a parte
 * nativa fica no bloco C++ abaixo (Windows, macOS/iOS e Linux/Android).
 *
 * Uso: chame PrismaStats.update(elapsed) todo frame (ele so recalcula 1x por
 * segundo) e leia gameRam, deviceRam e cpuPercent.
 */
@:cppFileCode('
#include <ctime>
#include <thread>
#if defined(_WIN32)
#include <windows.h>
static double prisma_total_ram() {
	MEMORYSTATUSEX m;
	m.dwLength = sizeof(m);
	GlobalMemoryStatusEx(&m);
	return (double)m.ullTotalPhys;
}
static double prisma_cpu_seconds() {
	FILETIME c, e, k, u;
	GetProcessTimes(GetCurrentProcess(), &c, &e, &k, &u);
	ULARGE_INTEGER a, b;
	a.LowPart = k.dwLowDateTime; a.HighPart = k.dwHighDateTime;
	b.LowPart = u.dwLowDateTime; b.HighPart = u.dwHighDateTime;
	return (double)(a.QuadPart + b.QuadPart) / 10000000.0;
}
#elif defined(__APPLE__)
#include <sys/types.h>
#include <sys/sysctl.h>
static double prisma_total_ram() {
	int64_t mem = 0;
	size_t len = sizeof(mem);
	sysctlbyname("hw.memsize", &mem, &len, NULL, 0);
	return (double)mem;
}
static double prisma_cpu_seconds() { return (double)clock() / CLOCKS_PER_SEC; }
#else
#include <unistd.h>
static double prisma_total_ram() {
	return (double)sysconf(_SC_PHYS_PAGES) * (double)sysconf(_SC_PAGESIZE);
}
static double prisma_cpu_seconds() { return (double)clock() / CLOCKS_PER_SEC; }
#endif
')
class PrismaStats
{
	/** RAM usada pelo jogo (bytes). */
	public static var gameRam(default, null):Float = 0;

	/** RAM total do aparelho (bytes). 0 = indisponivel. */
	public static var deviceRam(default, null):Float = 0;

	/** CPU usada pelo jogo, 0-100 (media de todos os nucleos). */
	public static var cpuPercent(default, null):Float = 0;

	static var timer:Float = 1;
	static var cores:Int = 1;
	static var lastCpu:Float = 0;
	static var lastWall:Float = 0;

	public static function update(elapsed:Float):Void
	{
		timer += elapsed;
		if (timer < 1) return;
		timer = 0;

		gameRam = System.totalMemoryNumber;

		#if cpp
		if (deviceRam <= 0)
		{
			deviceRam = untyped __cpp__("prisma_total_ram()");
			var n:Int = untyped __cpp__("(int)std::thread::hardware_concurrency()");
			cores = n < 1 ? 1 : n;
		}

		var cpu:Float = untyped __cpp__("prisma_cpu_seconds()");
		var wall:Float = Timer.stamp();
		if (lastWall > 0 && wall > lastWall)
			cpuPercent = Math.max(0, Math.min(100, (cpu - lastCpu) / (wall - lastWall) / cores * 100));
		lastCpu = cpu;
		lastWall = wall;
		#end
	}

	/** Formata bytes: "512 MB" ou "7.4 GB". */
	public static function format(bytes:Float):String
	{
		if (bytes <= 0) return "N/A";
		if (bytes >= 1073741824) return (Math.round(bytes / 107374182.4) / 10) + " GB";
		return Math.round(bytes / 1048576) + " MB";
	}
}
