"""
llm_factory.py — Instancia ChatModels de LangChain para distintos proveedores LLM.
Proveedores soportados: openai | claude | ollama
"""
import os


def _require_key(env_var: str, provider_name: str) -> None:
    if not os.getenv(env_var):
        raise EnvironmentError(
            f"Falta la variable de entorno {env_var} para usar {provider_name}.\n"
            f"Defínela con: set {env_var}=tu_api_key  (Windows)\n"
            f"              export {env_var}=tu_api_key  (Unix)"
        )


def create_llm(provider: str, model=None, temperature: float = 0.2):
    """
    Instancia y devuelve un ChatModel de LangChain.

    Args:
        provider:    'openai' | 'claude' | 'ollama'
        model:       Nombre del modelo (None = usa el default del proveedor).
        temperature: Temperatura de sampling (0.0 – 1.0).
    """
    provider = provider.strip().lower()

    if provider == "openai":
        _require_key("OPENAI_API_KEY", "OpenAI")
        from langchain_openai import ChatOpenAI
        return ChatOpenAI(model=model or "gpt-4o", temperature=temperature)

    if provider == "claude":
        _require_key("ANTHROPIC_API_KEY", "Anthropic/Claude")
        from langchain_anthropic import ChatAnthropic
        return ChatAnthropic(model=model or "claude-sonnet-4-6",
                             temperature=temperature, max_tokens=8192)

    if provider == "ollama":
        from langchain_ollama import ChatOllama
        return ChatOllama(model=model or "llama3", temperature=temperature)

    raise ValueError(
        f"Proveedor desconocido: {provider!r}. "
        "Opciones válidas: openai, claude, ollama."
    )
