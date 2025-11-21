# SDL CLI

Ferramenta de linha de comando para formatar, validar e (futuramente) compilar arquivos da Service Definition Language (SDL) v0.2.

## Instalação

### Go (recomendado)
```bash
go install github.com/marcelsud/sdl-cli@latest
```
Certifique-se de que `$GOPATH/bin` esteja no `PATH`.

### Via curl/wget (binários publicados)
Quando houver releases, baixe e instale o binário mais recente:
```bash
# Linux/macOS (ajuste o sufixo conforme seu OS/CPU)
curl -L "https://github.com/marcelsud/sdl-cli/releases/latest/download/sdl-cli_$(uname -s)_$(uname -m).tar.gz" \
  | tar -xz -C /usr/local/bin sdl
# ou
wget -O- "https://github.com/marcelsud/sdl-cli/releases/latest/download/sdl-cli_$(uname -s)_$(uname -m).tar.gz" \
  | tar -xz -C /usr/local/bin sdl
```
(Substitua caminhos se preferir outra pasta. Os assets serão publicados nas releases do repositório.)

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
