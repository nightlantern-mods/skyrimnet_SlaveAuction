SkyrimNet Actions Repair - for SkyrimNet Slave Auction
======================================================

[English]

WHO NEEDS THIS
- You ran an auction with SkyrimNet Slave Auction 0.1.0: use this once.
- You started with 0.1.1 or later, or never ran an auction with 0.1.0: you do not need it.

WHY
0.1.0 rewrote, on every auction, the cooldowns of some actions that other mods add to SkyrimNet
(restraints, kidnapping, fights, dressing and more: up to 39 actions, only those of mods you have
installed), and SkyrimNet saved them in its Actions.yaml. Those mods then behave differently, even
outside the auction. This tool removes those entries, so each action goes back to the default its
own mod gives it.

WHAT IT CHANGES
- Only entries that hold exactly what 0.1.0 left: the action switched on, with a cooldown of 0 or
  7200 seconds.
- An entry with your own settings in it (the action switched off, another cooldown, another
  setting) is left as it is, and listed.
- Nothing else in the file. If no entry is left, the file is deleted, as on a fresh SkyrimNet install.
- Before changing anything it copies the file to Actions.yaml.bak, next to it.

HOW TO USE
1. Update SkyrimNet Slave Auction to 0.1.1 or later first. With 0.1.0 still installed, the next
   auction would change the file again.
2. Close Skyrim.
3. Find Actions.yaml:
   - Mod Organizer 2: right-click "Overwrite" at the bottom of the left pane and open it in Explorer,
     then go to SKSE\Plugins\SkyrimNet\config\Actions.yaml. If it is not there, look in the same
     place inside the SkyrimNet mod's folder.
   - Without MO2: Skyrim Special Edition\Data\SKSE\Plugins\SkyrimNet\config\Actions.yaml
4. Drag Actions.yaml onto RepairSkyrimNetActions.bat. A window shows what was removed.

TO UNDO
Delete Actions.yaml (if it is there) and rename Actions.yaml.bak to Actions.yaml.


[日本語]

使う必要がある人
- SkyrimNet Slave Auction 0.1.0 で競売を行った方: 1 回だけ使ってください。
- 0.1.1 以降から使い始めた方、0.1.0 で競売をしていない方: 使う必要はありません。

理由
0.1.0 は競売のたびに、他の MOD が SkyrimNet に追加している行動の一部（拘束具、誘拐、戦闘、
着替えなど。最大 39 種類で、導入している MOD の行動だけが対象）の待ち時間を書き換え、SkyrimNet
の設定 Actions.yaml に保存していました。そのため、それらの MOD の動きが競売の外でも変わります。
このツールはその項目を削除して、各行動をそれぞれの MOD が決めた初期値に戻します。

変更するもの
- 0.1.0 が残した内容そのままの項目だけ（行動が有効で、待ち時間が 0 秒か 7200 秒のもの）
- あなたの設定が入っている項目（行動を無効にしている、別の待ち時間、ほかの設定がある）は、
  そのままにして一覧で知らせます
- ファイルのほかの部分は変えません。項目が 1 つも残らないときは、SkyrimNet の新規インストールと
  同じく、ファイルを削除します
- 変更の前に、同じ場所へ Actions.yaml.bak という控えを作ります

使い方
1. 先に SkyrimNet Slave Auction を 0.1.1 以降に更新する。0.1.0 のままだと、次の競売でまた書き
   換わります
2. Skyrim を終了する
3. Actions.yaml を探す
   - Mod Organizer 2 の場合: 左の一覧の一番下の「Overwrite」を右クリックしてエクスプローラーで
     開き、SKSE\Plugins\SkyrimNet\config\Actions.yaml に進む。そこになければ、SkyrimNet の
     MOD のフォルダの中の同じ場所を見てください
   - MO2 を使っていない場合: Skyrim Special Edition\Data\SKSE\Plugins\SkyrimNet\config\Actions.yaml
4. Actions.yaml を RepairSkyrimNetActions.bat の上にドラッグ＆ドロップする。削除した項目が
   画面に表示されます

元に戻すには
Actions.yaml があれば削除し、Actions.yaml.bak の名前を Actions.yaml に戻してください。
