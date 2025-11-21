# SDL CLI

Ferramenta de linha de comando para formatar, validar e (futuramente) compilar arquivos da Service Definition Language (SDL) v0.2.

## Instalação

### Go (recomendado)
```bash
go install github.com/marcelsud/sdl-cli@latest
```
Certifique-se de que `$GOPATH/bin` esteja no `PATH`.

### Via curl (binários publicados)
Quando houver releases, baixe e instale o binário mais recente:
```bash
curl -fsSL https://raw.githubusercontent.com/marcelsud/sdl-cli/main/tools/install.sh | sh
```
Ou baixe diretamente da página de releases (`dist/sdl-cli_<os>_<arch>.tar.gz`) e extraia manualmente, ou compile com `go build ./...`.

## Uso

```bash
sdl fmt [path]      # formata arquivos .sdl (default: recursivo a partir de .)
sdl validate [path] # valida .sdl contra a spec
sdl compile [path]  # placeholder (ainda não implementado)
```

### Formatter
- Sobrescreve por padrão. Flags:
  - `--check`: não escreve, falha se houver diferenças (exit 3).
  - `--diff`: mostra diff, não escreve.
  - `--write`: controla escrita (default true).
  - `--actions=auto|single|multi`: layout de ações (auto quebra linhas quando > `--line-length`).
  - `--line-length`: limite para `--actions=auto` (default 100; 0 desativa o limite).

### Validação
- Procura todos os `.sdl` no diretório (ou arquivo/pasta passada).
- Regras da v0.2: `calls` (sincrono) e `emits/->` (eventos) suportados; referência de tipos, genéricos, erros, eventos declarados, etc.
- Exit 1 em erros; warnings são impressos mas não falham.

## Exemplos
- `examples/checkout.sdl`: estilo single-line com `calls/emits` inline.
- `examples/checkout_multiline.sdl`: multilinha com `calls` e `emits` em blocos.
- `examples/checkout_many_calls.sdl`: múltiplos serviços chamados/em event emitidos, com comentários de bloco/linha.

## Licença
MIT. Veja `LICENSE`.
