# bedrock-server-systemd

[SERVER SOFTWARE (ALPHA) FOR MINECRAFT](https://www.minecraft.net/en-us/download/server/bedrock) を systemd で動かすための諸々。

## 中身

* bedrock-server.service
  * Bedrock Server そのもの
* bedrock-server.socket
  * Bedrock Server のコンソールに入力するための FIFO ソケット
* bedrock-server-backup.service
  * `save` コマンドを利用したバックアップスクリプトを実行するサービス
* bedrock-server-backup.timer
  * バックアップ用タイマー
* bedrock-server-backup.sh
  * バックアップスクリプト

## セットアップ

おおよそこんな感じ。

* サーバをダウンロードして `/var/lib/minecraft/bedrock-server` に展開する
* ユニットファイルを `/etc/systemd/system` に配置する
* `systemctl daemon-reload`
* サーバ起動 `systemctl enable --now bedrock-server.service`
* バックアップスクリプトを `/var/lib/minecraft/scripts` に配置
* バックアップ有効化 `systemctl enable --now bedrock-server-backup.timer`
