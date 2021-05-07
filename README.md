# Oracle FunctionsでEmail Deliveryと連携しメール送信

表題を実行するためのソースコードです。

## セットアップ、実行について

以下、手順となります。
[Oracle FunctionsでEmail Deliveryと連携しメール送信](https://qiita.com/y-araki-qiita/items/5a580bb739b37198300d)

こちらはスクリプトを実行してメールを送信する手順ですが、
func.goの中身を修正すれば
fn invoke fn-email-app sendemail
とコマンドを打つだけで実行されます。

Oracle Functionsはオープンソースベースのサーバレスサービスのため、
ファンクション単体でも実行できますし、Linuxコマンドやスクリプトと連携して
実行することもできます。

是非、試してみてください
