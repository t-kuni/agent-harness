以下は、公式 Git docs を確認したうえでの整理です。結論から言うと、このユースケースでは **「テンプレート元コミットのハッシュを派生先に記録し、その範囲差分を `git apply -3` または `git am -3` で適用する方式」** が最も扱いやすいです。

**前提**
どの方式でも、作業前に必ず更新用ブランチを切るのが安全です。

```bash
git status --porcelain   # 空であることを確認
git switch -c template-update-20260513
```

| 方式 | 適性 | スクリプト化 |
|---|---:|---:|
| `format-patch` / `git am` | コミット単位で取り込みたい場合に有効 | 4/5 |
| upstream remote + merge/rebase | 履歴を接続できるなら有効。無関係履歴のままはつらい | 3/5 |
| `git subtree` | テンプレートをサブディレクトリとして持つ設計なら有効 | 2/5 |
| `git submodule` | テンプレートを独立部品として参照したい場合向け | 2/5 |
| ハッシュ記録 + 差分適用 | 今回の主用途に最も合う | 5/5 |

**1. `git format-patch` / `git am`**
手順:

```bash
# 派生先 repo
git remote add template https://example.com/template.git
git fetch template

BASE=<派生時点のテンプレートコミット>
LATEST=template/main

git format-patch --binary --stdout "$BASE..$LATEST" | git am -3
```

メリット:
`git am` はパッチをコミットとして適用するため、テンプレート側のコミットメッセージや作者情報を残しやすいです。Git 公式例にも `git format-patch ... | git am -3` の形があります。

デメリット・注意点:
`format-patch` は通常のパッチ列なので、マージコミットの構造は再現しません。テンプレート側の履歴がマージ中心だと、履歴の忠実性は落ちます。また、派生先で同じ箇所を大きく変更していると、コミットごとに何度もコンフリクトします。

コンフリクト時:

```bash
# ファイルを編集して解決
git add <resolved-files>
git am --continue

# そのパッチを諦める
git am --skip

# 全体を中止
git am --abort
```

`git am -3` は、パッチがその元 blob 情報を持ち、ローカルに blob があれば 3-way merge にフォールバックします。

**2. upstream remote を追加して merge/rebase**
`.git` を削除して独立 repo にした後でも、remote 追加自体は可能です。

```bash
git remote add upstream https://example.com/template.git
git fetch upstream
```

ただし、履歴は無関係なので、単純な merge は通常拒否されます。

```bash
git merge upstream/main
# fatal: refusing to merge unrelated histories
```

強制するなら:

```bash
git merge --allow-unrelated-histories upstream/main
```

しかしこれは、共通祖先がないため、初回は大量の add/add コンフリクトになりがちです。

より良い手順は、派生時点のテンプレートコミット `BASE` が分かる場合に、まず履歴上の接続点を作る方法です。

```bash
git remote add upstream https://example.com/template.git
git fetch upstream

BASE=<派生時点のテンプレートコミット>

# 現在の派生先ツリーは維持しつつ、BASE を履歴上の親として記録する
git merge -s ours --allow-unrelated-histories "$BASE" \
  -m "Record template base $BASE"

# 以後は BASE を共通祖先として通常 merge できる
git merge upstream/main
```

メリット:
一度うまく接続できれば、その後は通常の Git merge として運用できます。

デメリット・注意点:
`BASE` が不明だと精度が落ちます。`--allow-unrelated-histories` だけで突っ込むのは、初回コンフリクトが重くなりやすいです。rebase はさらに注意が必要で、`git rebase --root --onto upstream/main` のような形は、派生先の初期スナップショット全体を再適用しようとしてコンフリクトしやすく、通常は推奨しません。

コンフリクト時:

```bash
git status
# 編集して解決
git add <resolved-files>
git merge --continue

# 中止
git merge --abort
```

rebase の場合は `git rebase --continue` / `--abort` / `--skip` です。

**3. `git subtree`**
`subtree` は、外部 repo をメイン repo のサブディレクトリとして取り込む方式です。

```bash
git subtree add --prefix=template https://example.com/template.git main --squash
git subtree pull --prefix=template https://example.com/template.git main --squash
```

メリット:
submodule と違い、利用者が別途 submodule 初期化をする必要がありません。テンプレートを `template/` や `vendor/template/` のようなディレクトリに閉じ込める設計なら扱いやすいです。

デメリット・注意点:
今回のように「テンプレートのファイルが repo ルートに展開され、その上に利用者が開発する」形とは相性が悪いです。`subtree` は基本的に `--prefix` 配下を管理するため、ルート全体を後から自然に subtree 化する用途には向きません。

後付け可否:
サブディレクトリとしてなら後付け可能です。ただし既存ファイルが同じパスにある場合は、退避、削除、subtree add、ローカル変更の再適用が必要です。

コンフリクト時:
`git subtree pull` は内部的には merge なので、通常の merge と同じく編集、`git add`、commit で解決します。

**4. `git submodule`**
submodule は、テンプレート repo を別 repo のまま特定パスに置き、親 repo はその commit hash を記録する方式です。

```bash
git submodule add -b main https://example.com/template.git template
git commit -m "Add template submodule"

# 更新
git submodule update --remote template
git add template
git commit -m "Update template submodule"
```

利用者側 clone 後:

```bash
git submodule update --init --recursive
```

メリット:
テンプレートを完全に独立した repo として扱えます。親 repo には「どのテンプレート commit を参照しているか」が明確に残ります。

デメリット・注意点:
テンプレート更新は派生先のファイルへ直接 merge されるのではなく、submodule の参照 commit が変わるだけです。今回の「テンプレートの更新を派生先 repo の既存ファイルへ取り込む」用途には合いません。

後付け可否:
サブディレクトリとしてなら可能です。既存パスが通常ファイル群なら、退避または削除が必要です。repo ルートそのものを submodule にすることは、親 repo の構造上できません。

コンフリクト時:
親 repo では gitlink の競合になります。対象 submodule 内で適切な commit を checkout または merge し、親 repo 側で `git add template` して commit します。

**5. コミットハッシュ記録 + 差分生成・適用**
派生時にテンプレートの commit hash を記録しておきます。

```bash
git rev-parse HEAD > .template-version
```

派生先 repo 側には、例えば次を置きます。

```text
.template-version
```

中身:

```text
abc1234...
```

更新スクリプトのイメージ:

```bash
#!/usr/bin/env bash
set -euo pipefail

remote=template
url="https://example.com/template.git"
branch="main"

base="$(cat .template-version)"

git diff --quiet
git diff --cached --quiet

git remote get-url "$remote" >/dev/null 2>&1 || git remote add "$remote" "$url"
git fetch "$remote" "$branch"

latest="$(git rev-parse "$remote/$branch")"

git switch -c "template-update-${latest:0:12}"

git diff --binary "$base" "$latest" > .git/template-update.patch

git apply --check --3way .git/template-update.patch
git apply --3way --index .git/template-update.patch

printf '%s\n' "$latest" > .template-version
git add .template-version
git commit -m "Apply template updates ${base:0:12}..${latest:0:12}"
```

メリット:
最もスクリプト化しやすく、派生先の履歴を壊しません。テンプレート更新を「前回取り込み済み hash から最新 hash までの差分」として明確に扱えます。`git diff --binary` を使えばバイナリ差分にも対応しやすいです。

デメリット・注意点:
テンプレート側の個別コミット履歴は派生先に残りません。1コミットで「テンプレート更新を適用」として残る形です。個別コミットを残したい場合は、同じ `base..latest` に対して `format-patch | git am -3` を使う方がよいです。

コンフリクト時:
`git apply --3way` が止まったら、通常どおりファイルを編集します。

```bash
git status
# コンフリクト解決
git add <resolved-files>

latest="$(git rev-parse template/main)"
printf '%s\n' "$latest" > .template-version
git add .template-version

git commit -m "Apply template updates"
```

この方式では `git am` のようなシーケンス状態がないため、必ず専用ブランチで実行するのが重要です。

**推薦**
今回の「`.git` を削除して独立させた派生先 repo に、後からテンプレート更新を取り込む」用途では、第一候補は **5. コミットハッシュ記録 + 差分適用** です。

理由は、派生先がテンプレート repo と履歴上つながっていない前提でも、`BASE..LATEST` という更新範囲を明示でき、スクリプト化しやすく、派生先の独自履歴を壊さないためです。テンプレート側のコミット単位も残したい場合だけ、5 の差分適用部分を `git format-patch --stdout "$BASE..$LATEST" | git am -3` に差し替えるのが現実的です。

今後の運用を改善できるなら、派生時に `.template-version` を必ず入れておくのが最重要です。さらに余裕があれば、初回に `git merge -s ours --allow-unrelated-histories <BASE>` で履歴接続点を作っておくと、以後は通常の upstream merge に近い運用も可能になります。

参考: [git-format-patch](https://git-scm.com/docs/git-format-patch), [git-am](https://git-scm.com/docs/git-am.html), [git-merge](https://git-scm.com/docs/git-merge/2.47.0), [git-remote](https://git-scm.com/docs/git-remote), [git-apply](https://git-scm.com/docs/git-apply/2.29.0.html), [git-submodule](https://git-scm.com/docs/git-submodule.html), [git-subtree docs in git.git](https://kernel.googlesource.com/pub/scm/git/git/+/b3b9e5c1718e59d2a835291bbc9c28b1762c45ce/contrib/subtree/git-subtree.txt)
