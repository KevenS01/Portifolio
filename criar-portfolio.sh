#!/usr/bin/env bash
# Automatiza a Parte A: repositório, branches, commits, Pull Requests e GitHub Pages.
# Requisitos: git e GitHub CLI (gh) instalados e logados (gh auth login).
set -euo pipefail

############ EDITE AQUI ############
USUARIO="seu-usuario-github"
NOME_COMPLETO="Seu Nome"
SLUG="seu-nome"                     # minúsculas, sem espaço (ex.: maria-silva)
EMAIL="seu@email.com"
LINKEDIN="https://www.linkedin.com/in/seu-perfil"
SOBRE="Sou estudante de desenvolvimento web, apaixonado(a) por tecnologia e por criar projetos úteis."
PROJ1_NOME="Nome do Projeto 1";  PROJ1_DESC="Descrição curta do projeto 1.";  PROJ1_URL="https://github.com/$USUARIO/repo-projeto-1"
PROJ2_NOME="Nome do Projeto 2";  PROJ2_DESC="Descrição curta do projeto 2.";  PROJ2_URL="https://github.com/$USUARIO/repo-projeto-2"
FOTO="./foto.jpg"                   # opcional: coloque sua foto aqui, ao lado do script
####################################

REPO="portfolio-$SLUG"
SITE="https://$USUARIO.github.io/$REPO"

command -v gh >/dev/null || { echo "Instale o GitHub CLI: https://cli.github.com"; exit 1; }
FOTO_ABS=""; [ -f "$FOTO" ] && FOTO_ABS="$(cd "$(dirname "$FOTO")" && pwd)/$(basename "$FOTO")"

# insere texto (arg 3) no lugar de um marcador (arg 2) dentro do arquivo (arg 1)
inserir() { python3 - "$1" "$2" "$3" <<'PY'
import sys
f, marcador, texto = sys.argv[1:4]
c = open(f, encoding="utf-8").read()
open(f, "w", encoding="utf-8").write(c.replace(marcador, texto))
PY
}

# fluxo de PR: push, abre PR e faz o merge
fechar_branch() {
  git push -u origin "$1"
  gh pr create --base main --head "$1" --title "$2" --body "$3"
  gh pr merge "$1" --merge --delete-branch
  git checkout main && git pull
}

# ---------- 1. Criar o repositório ----------
gh repo create "$REPO" --public --add-readme --gitignore Node --clone
cd "$REPO"

# ---------- 2. Estruturar o projeto ----------
mkdir -p css img projetos
touch img/.gitkeep projetos/.gitkeep
cat > index.html <<HTML
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Portfólio | $NOME_COMPLETO</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <!--INICIO-->
  <!--PROJETOS-->
  <!--CONTATO-->
  <footer><p>&copy; 2026 $NOME_COMPLETO</p></footer>
</body>
</html>
HTML
git add . && git commit -m "chore: estrutura inicial do projeto" && git push

# ---------- 3a. feature/pagina-inicial ----------
git checkout -b feature/pagina-inicial
inserir index.html "<!--INICIO-->" "<header>
    <img src=\"img/foto.jpg\" alt=\"Foto de $NOME_COMPLETO\" class=\"foto\">
    <h1>$NOME_COMPLETO</h1>
    <p>$SOBRE</p>
  </header>"
git commit -am "feat: adiciona apresentação na página inicial"

cat > css/style.css <<'CSS'
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: Arial, Helvetica, sans-serif; line-height: 1.6; color: #222; background: #f5f7fa; }
header { text-align: center; padding: 3rem 1rem; background: #1f3a5f; color: #fff; }
header h1 { margin: 1rem 0 .5rem; }
header p { max-width: 600px; margin: 0 auto; }
.foto { width: 160px; height: 160px; border-radius: 50%; object-fit: cover; border: 4px solid #fff; background: #ccc; }
section { max-width: 800px; margin: 2rem auto; padding: 0 1rem; }
section h2 { margin-bottom: 1rem; color: #1f3a5f; }
footer { text-align: center; padding: 1.5rem; color: #666; }
CSS
git add css/style.css && git commit -m "style: adiciona estilos base e cabeçalho"

if [ -n "$FOTO_ABS" ]; then
  cp "$FOTO_ABS" img/foto.jpg
  git add img/foto.jpg && git commit -m "feat: adiciona foto de perfil"
fi
fechar_branch feature/pagina-inicial "Página inicial" "Adiciona apresentação, foto e estilos base."

# ---------- 3b. feature/projetos ----------
git checkout -b feature/projetos
inserir index.html "<!--PROJETOS-->" "<section id=\"projetos\">
    <h2>Projetos</h2>
    <ul class=\"lista-projetos\">
      <li><a href=\"$PROJ1_URL\" target=\"_blank\">$PROJ1_NOME</a> — $PROJ1_DESC</li>
      <li><a href=\"$PROJ2_URL\" target=\"_blank\">$PROJ2_NOME</a> — $PROJ2_DESC</li>
    </ul>
  </section>"
git commit -am "feat: adiciona lista de projetos com links"

cat >> css/style.css <<'CSS'

.lista-projetos { list-style: none; }
.lista-projetos li { background: #fff; padding: 1rem; margin-bottom: .75rem; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.1); }
.lista-projetos a { color: #1f3a5f; font-weight: bold; }
CSS
git commit -am "style: estiliza a seção de projetos"
fechar_branch feature/projetos "Seção de projetos" "Lista com 2 projetos e link para cada repositório."

# ---------- 3c. feature/contato ----------
git checkout -b feature/contato
inserir index.html "<!--CONTATO-->" "<section id=\"contato\">
    <h2>Contato</h2>
    <ul class=\"lista-contato\">
      <li>E-mail: <a href=\"mailto:$EMAIL\">$EMAIL</a></li>
      <li>LinkedIn: <a href=\"$LINKEDIN\" target=\"_blank\">$LINKEDIN</a></li>
      <li>GitHub: <a href=\"https://github.com/$USUARIO\" target=\"_blank\">github.com/$USUARIO</a></li>
    </ul>
  </section>"
git commit -am "feat: adiciona seção de contato"

cat >> css/style.css <<'CSS'

.lista-contato { list-style: none; }
.lista-contato li { margin-bottom: .5rem; }
.lista-contato a { color: #1f3a5f; }
CSS
git commit -am "style: estiliza a seção de contato"
fechar_branch feature/contato "Seção de contato" "Adiciona e-mail, LinkedIn e GitHub."

# ---------- 4. Publicar com GitHub Pages ----------
gh api -X POST "repos/$USUARIO/$REPO/pages" -f "source[branch]=main" -f "source[path]=/" \
  || echo "Pages já pode estar ativo; confira em Settings > Pages."

# ---------- 5. README ----------
cat > README.md <<MD
# Portfólio — $NOME_COMPLETO

Site de portfólio pessoal com apresentação, projetos e contatos.

🔗 **Site publicado:** $SITE

## Tecnologias usadas

- HTML5
- CSS3
- Git e GitHub (branches e Pull Requests)
- GitHub Pages (hospedagem)

## Estrutura

\`\`\`
$REPO/
├── index.html
├── css/
├── img/
├── projetos/
└── README.md
\`\`\`
MD
git add README.md && git commit -m "docs: escreve README com descrição, link e tecnologias" && git push

echo
echo "Pronto! Repositório: https://github.com/$USUARIO/$REPO"
echo "Site (leva 1-2 min para ficar no ar): $SITE"
