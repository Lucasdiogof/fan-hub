# Logos dos parceiros — Red Bull Bragantino

Fonte oficial verificada em 10/09/2026:
https://www.redbullbragantino.com/br-pt/parceiros

Foram identificados 17 parceiros:
- 5 Patrocinadores Premium
- 6 Patrocinadores Regionais
- 6 Fornecedores Oficiais

## Baixar as imagens originais do CDN oficial

### Opção recomendada para projeto Flutter/Dart

Na raiz do projeto:

```bash
dart run caminho/para/download_partners.dart
```

O script cria:

```text
assets/partners/
```

e baixa os 17 arquivos com nomes estáveis, por exemplo:

```text
puma.png
asaas.png
nd.png
curaprox.png
knn-idiomas.png
...
trendx.png
```

### Alternativa com Python

```bash
python download_partners.py
```

## Flutter

Adicione ao `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/partners/
```

O arquivo `partners.dart` já contém uma lista pronta com `name`, `category` e `assetPath`.

## Arquivos do pacote

- `partners.json`: manifest completo com nome, categoria e URL-fonte oficial.
- `partners.csv`: mesma relação em formato tabular.
- `download_partners.dart`: downloader sem dependências externas.
- `download_partners.py`: downloader alternativo.
- `partners.dart`: catálogo Flutter pronto para usar.
- `pubspec_snippet.yaml`: trecho para assets.

Observação: logotipos e marcas pertencem aos respectivos titulares. Garanta que o uso no aplicativo esteja coberto pela autorização/licença aplicável.
