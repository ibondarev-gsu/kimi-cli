"""Monkey-patch aiohttp and httpx/openai for proxy and SSL compatibility with Tinkoff NGFW."""

import ssl

import aiohttp
import certifi
import httpx

# Patch 1: replace new_client_session to add trust_env=True and drop explicit connector
# so that aiohttp can pick up HTTP_PROXY/HTTPS_PROXY from the environment.
import kimi_cli.utils.aiohttp as _kimi_aiohttp

_ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
_ssl_ctx.load_verify_locations(cafile=certifi.where())
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_REQUIRED
# Disable strict AKI requirement (Python 3.12+ breaks on old corporate CAs)
if hasattr(ssl, "VERIFY_X509_STRICT"):
    _ssl_ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
_kimi_aiohttp._ssl_context = _ssl_ctx

_orig_new_client_session = _kimi_aiohttp.new_client_session


def _patched_new_client_session(*, timeout=None):
    return aiohttp.ClientSession(
        connector=aiohttp.TCPConnector(ssl=_kimi_aiohttp._ssl_context),
        timeout=timeout or _kimi_aiohttp._DEFAULT_TIMEOUT,
        trust_env=True,
    )


_kimi_aiohttp.new_client_session = _patched_new_client_session

# Patch 3: inject proxy-aware httpx client into OpenAI SDK (used for LLM API calls)
import kosong.chat_provider.openai_common as _openai_common

_httpx_ssl_ctx = ssl.create_default_context(cafile=certifi.where())
if hasattr(ssl, "VERIFY_X509_STRICT"):
    _httpx_ssl_ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT

_orig_create = _openai_common.create_openai_client


def _patched_create_openai_client(*, api_key, base_url, client_kwargs):
    kwargs = dict(client_kwargs)
    if "http_client" not in kwargs:
        kwargs["http_client"] = httpx.AsyncClient(verify=_httpx_ssl_ctx, trust_env=True)
    return _orig_create(api_key=api_key, base_url=base_url, client_kwargs=kwargs)


_openai_common.create_openai_client = _patched_create_openai_client

# Also patch all other known modules that import create_openai_client directly
import importlib
for _mod_name in (
    "kosong.chat_provider.kimi",
    "kosong.contrib.chat_provider.openai_legacy",
    "kosong.contrib.chat_provider.openai_responses",
):
    try:
        _mod = importlib.import_module(_mod_name)
        if hasattr(_mod, "create_openai_client"):
            _mod.create_openai_client = _patched_create_openai_client
    except ImportError:
        pass
