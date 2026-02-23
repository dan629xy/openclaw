// Preload script: patches Node.js global fetch to use HTTP proxy
// Loaded via NODE_OPTIONS=--require /app/proxy-setup.cjs
const proxyUrl =
  process.env.https_proxy ||
  process.env.HTTPS_PROXY ||
  process.env.http_proxy ||
  process.env.HTTP_PROXY;

if (proxyUrl) {
  try {
    const { ProxyAgent, setGlobalDispatcher } = require("undici");
    setGlobalDispatcher(new ProxyAgent(proxyUrl));
  } catch (e) {
    console.warn("[proxy-setup] Failed to set proxy:", e.message);
  }
}
