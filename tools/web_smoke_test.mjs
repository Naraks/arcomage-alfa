// ARC-075: открывает собранный Web-экспорт (ARC-067) headless Chromium'ом через
// Playwright и падает, если во время загрузки/старта в консоли браузера
// появляются ошибки (WASM-крэши, JS-исключения) — юнит-тесты (ARC-072/073) в
// принципе не могут это поймать, так как крутятся внутри Godot, а не в браузере,
// и не проверяют, что реальный HTML5-билд вообще запускается.
//
// Локальный запуск (после `godot --headless --export-release "Web" ./web/index.html`):
//   npm install --no-save playwright
//   npx playwright install --with-deps chromium
//   node tools/web_smoke_test.mjs web 8060
//
// В CI см. .github/workflows/ci.yml, джоб smoke-test-web.

import { chromium } from "playwright";
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";

const WEB_DIR = process.argv[2] ?? "web";
const PORT = Number(process.argv[3] ?? 8060);
// Загрузка + компиляция WASM в headless-окружении CI без прогретого кэша
// занимает заметно больше, чем на десктопе разработчика — ждём с запасом.
const BOOT_WAIT_MS = 20000;

const MIME = {
	".html": "text/html",
	".js": "application/javascript",
	".wasm": "application/wasm",
	".pck": "application/octet-stream",
	".png": "image/png",
	".json": "application/json",
	".ico": "image/x-icon",
};

function serveStatic(webDir, port) {
	const server = createServer(async (req, res) => {
		let urlPath = req.url === "/" ? "/index.html" : req.url;
		urlPath = decodeURIComponent(urlPath.split("?")[0]);
		const filePath = join(webDir, urlPath);
		try {
			const data = await readFile(filePath);
			res.writeHead(200, {
				"Content-Type": MIME[extname(filePath)] ?? "application/octet-stream",
			});
			res.end(data);
		} catch {
			res.writeHead(404);
			res.end("not found");
		}
	});
	return new Promise((resolve) => server.listen(port, () => resolve(server)));
}

async function main() {
	const server = await serveStatic(WEB_DIR, PORT);
	// thread_support=false в export_presets.cfg, поэтому SharedArrayBuffer и
	// COOP/COEP-заголовки не нужны — обычный статический сервер достаточен.
	const browser = await chromium.launch({
		// Headless Chromium без этих флагов не создаёт WebGL-контекст (нет GPU) —
		// Godot тогда падает на старте рендерера ещё до отрисовки главного меню.
		args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
	});
	const page = await browser.newPage();

	const errors = [];
	page.on("console", (msg) => {
		if (msg.type() === "error") errors.push(`[console] ${msg.text()}`);
	});
	page.on("pageerror", (err) => errors.push(`[pageerror] ${err.message}`));
	page.on("requestfailed", (req) => {
		errors.push(`[requestfailed] ${req.url()} — ${req.failure()?.errorText}`);
	});

	console.log(`Открываю http://localhost:${PORT}/index.html ...`);
	await page.goto(`http://localhost:${PORT}/index.html`, { waitUntil: "load" });

	console.log(`Жду ${BOOT_WAIT_MS}мс на загрузку и старт движка...`);
	await page.waitForTimeout(BOOT_WAIT_MS);

	await page.screenshot({ path: "web-smoke-screenshot.png" }).catch(() => {});

	const canvas = await page.$("canvas");
	if (!canvas) {
		errors.push("canvas не найден в DOM — движок Godot не смонтировался");
	} else {
		const box = await canvas.boundingBox();
		if (!box || box.width === 0 || box.height === 0) {
			errors.push("canvas имеет нулевой размер — похоже, движок не отрисовался");
		}
	}

	await browser.close();
	server.close();

	if (errors.length > 0) {
		console.error(`Smoke-тест провалился (${errors.length} ошибок):`);
		for (const e of errors) console.error(" -", e);
		process.exitCode = 1;
		return;
	}

	console.log("Smoke-тест пройден: ошибок в консоли нет, canvas отрисован.");
}

main().catch((err) => {
	console.error("Smoke-тест упал с исключением:", err);
	process.exitCode = 1;
});
