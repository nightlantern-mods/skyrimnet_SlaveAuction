# SkyrimNet 奴隷オークションの入口 MOD・出口 MOD の作り方

この MOD をマスターにする必要はなく、この MOD があなたの MOD を知っている必要もありません。入口 MOD はイベントを 1 つ送るだけで、出口 MOD は JSON ファイル 1 つと、自分のプラグインのマーカーで作れます。

インストーラーの 4 つのサンプルは動く見本で、ソース付きです。

| 作りたいもの | 読むもの |
|---|---|
| プレイヤーを含む入口 | `skyrimnet_SlaveAuction_EntryDefeat.psc` |
| フォロワーだけの入口 | `skyrimnet_SlaveAuction_EntryAbduction.psc` |
| いちばん小さい出口（スクリプトなし） | `skyrimnet_SlaveAuction_carriage.json` |
| 自分の場所とイベントを持つ出口 | `skyrimnet_SlaveAuction_ExitMine.psc` |

## 入口 MOD

どのフォームからでも、イベントを 1 つ送ります。

```papyrus
SendModEvent("skyrimnet_SlaveAuction_Capture", "defeated by bandits on the road")
SendModEvent("skyrimnet_SlaveAuction_Capture", "taken in the night", 1.0)   ; フォロワーだけ
```

文字列は捕まった経緯で、セリフの文脈として AI に渡します。500 文字を超えると切られるので、短くしてください。数値 1.0 を付けると、プレイヤーは捕まらず、フォロワーだけが捕まります。

結果はイベントで返ります。

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_CaptureResult", "OnCaptureResult")

Event OnCaptureResult(String result, String reason, Form requester)
	; requester は送り主。自分の依頼か確かめる
EndEvent
```

| 結果 | 意味 |
|---|---|
| `accepted` | 捕獲が始まった |
| `busy` | 競売の最中で、何も起きていない |
| `no_captives` | フォロワーだけを指定したが近くにいない、または名指しした NPC を誰も競りに出せないか、すでに競売に入っている |
| `full` | 檻に足そうとしたが、すでに 10 人いる |

- 競売 MOD が入っていなければ、返事は来ません。いつまでも待たないでください。
- 競売 MOD は全員の戦闘を止め、ダウン中の人を回復させます。死亡中の人は戻さず、子供は対象外です。
- 他の MOD のシーン中ではないかなど、呼んでよい状況かどうかは入口 MOD が確かめてください。
- それまでフォロワーを死なせたくなければ、Essential を付けた任意のエイリアスに入れます。入れている間だけ効きます。

### 競りに出す人を名指しする

フォロワーに限らず、どの NPC でも競りに出せます。イベントを送るフォームに一覧を入れて、数値 2.0 を付けて送ります。プレイヤーは捕まらず、客として入札します。

```papyrus
Form me = GetOwningQuest()
StorageUtil.FormListAdd(me, "skyrimnet_SlaveAuction_RequestedLots", someNpc)
StorageUtil.SetStringValue(me, "skyrimnet_SlaveAuction_RequestedExit", "author_second_stage")   ; 省略可
StorageUtil.SetIntValue(me, "skyrimnet_SlaveAuction_KeepLostLots", 1)                           ; 省略可
me.SendModEvent("skyrimnet_SlaveAuction_Capture", "bought to order for House Valerius", 2.0)
```

| キー | 内容 |
|---|---|
| `skyrimnet_SlaveAuction_RequestedLots` | 捕まえる人。どこにいても捕まります。最大 10 人で、それより多い分は無視します |
| `skyrimnet_SlaveAuction_RequestedExit` | プレイヤーが落札した人を送る `lots_bought` の出口の `id` |
| `skyrimnet_SlaveAuction_KeepLostLots` | 1 にすると、他の買い手が落札した人を `followers_sold` の出口へ送らず、競売場に残します。受付で買い戻せます |

- **古い版は数値 2.0 を知らないので、プレイヤーを捕まえてしまいます。** 先に確認してください：`StorageUtil.GetIntValue(None, "skyrimnet_SlaveAuction_ApiLevel") >= 2`
- この 3 つは返事のたびに空になります。依頼のたびに入れ直してください。
- 死亡中、無効化中、子供、プレイヤー、競売 MOD の NPC は除きます。誰も残らなければ結果は `no_captives` です。
- プレイヤーの近くにいる他のフォロワーは捕まりません。
- 買い戻し待ちの人も指定できます。その人は買い戻しの一覧から外れます。

プレイヤーを含まない競売が終わると、聞いている全員にイベントが届きます。誰も落札できなかったときは、これが唯一の知らせです。

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Closed", "OnAuctionClosed")

Event OnAuctionClosed(Form requester, String result, Int bought, Int lost)
	; requester は依頼元で、受付の競売では None。result は "closed"、競売場の戦闘で中止なら "aborted"
EndEvent
```

プレイヤーが来ないままゲーム内で 3 日たつと、画面の外で全員が売られ、このイベントが届きます。

### 檻に 1 人ずつ足す

数値 3.0 は同じ依頼で、暗転と通知がありません。表示は MOD 側で自由に決められます。待機中の競売があれば、その檻に足します。競りは、プレイヤーが見張りに話しかけるまで始まりません。

```papyrus
Form me = GetOwningQuest()
StorageUtil.FormListAdd(me, "skyrimnet_SlaveAuction_RequestedLots", someNpc)
me.SendModEvent("skyrimnet_SlaveAuction_Capture", "seized on the road", 3.0)
```

- 競売がなければ、最初の依頼で始まります。経緯の文字列、出口、`KeepLostLots` は競売の間ずっと最初の依頼のものを使い、あとの依頼の分は無視します。
- 舞台に誰もいなければ、競りの合間にも足せます。競りの最中と、プレイヤーを含む競売では `busy` です。
- 3 日の期限は、最後に足した時点から数え直します。
- **檻に人がいる間は、他の捕獲の依頼はすべて `busy` です。** 競売は 1 つずつなので、受付の酒も他の入口 MOD も同じです。プレイヤーを送る敗北系の MOD は、この返事のときの逃げ道を用意してください。
- 最初の依頼は、捕まった全員の一覧ができる前に返事をします。前の競売の人は、返事の時点で一覧から消えています。人数を数えるときは、自分の NPC が一覧に入るまで待ってください。

## 出口 MOD

JSON ファイルを 1 つ書きます。

`SKSE/Plugins/skyrimnet_SlaveAuction/exits/<作者名>_<名前>.json`

競売 MOD がフォルダを読むので、登録の作業はいりません。ファイル名の先頭には作者名を付けてください。同じ名前のファイルは上書きされます。翻訳 MOD は、同じ名前のファイルで表示を差し替えられます。

```json
{
  "string": {
    "id": "author_noble_house",
    "name": "Sold to a Noble House",
    "plugin": "MyExitMod.esp",
    "marker": "0x804",
    "event": "MyExitMod_Start",
    "for": "player_sold",
    "buyer_name": "Agent of House Valerius",
    "buyer_role": "A cold, polite agent buying servants for a noble house."
  },
  "int": {
    "api_version": 1,
    "weight": 10,
    "buyer_female": 0
  }
}
```

| 項目 | 必須 | 内容 |
|---|---|---|
| `api_version` | ○ | 1 |
| `id` | ○ | すべての出口の中で重ならない ID |
| `name` | ○ | MCM に出す名前 |
| `plugin` | ○ | 自分のプラグイン。読み込まれていなければ候補から外す |
| `marker` | ○ | 自分のプラグインの**永続**マーカーの FormID（16 進の文字列）。セルは直接指定できない |
| `for` | | `player_sold`（省略時）、`followers_sold`、`followers_bought`、`lots_bought` |
| `each_lot` | | `followers_sold` の出口で 1 にすると、売れた人がすぐ届き、合図は 1 人につき 1 回になる |
| `event` | | 到着後に送るイベント。移動だけの出口では書かない |
| `requires` | | 出口が必要とするほかのプラグイン。カンマで区切る。1 つでも読み込まれていなければ出口は使われず、MCM に足りないものが表示される |
| `weight` | | 同じ種類の中で選ばれる確率の比率。省略時は 10。0 以下は候補から外す |
| `buyer_name` | | 名前を付けた買い手が席に座り、できる限り落札する |
| `buyer_role` | | その買い手の役割。AI に渡す |
| `buyer_female` | | 0 は男性、1 は女性 |

読み込めない定義は、理由と一緒に MCM に出ます。

### 種類

| 種類 | 移動する人 | 出口がないとき |
|---|---|---|
| `player_sold` | プレイヤーとフォロワー全員。返事をするまで暗転したまま | 解放戦線の結末 |
| `followers_sold` | 他の買い手が落札したフォロワーだけ。プレイヤーには何も見えない。**取り戻す手段を用意してください** | 競売場で待ち、受付で買い戻せる |
| `followers_bought` | プレイヤーと、プレイヤーが落札したフォロワー。返事をするまで暗転したまま | その場で普通のフォロワーに戻る |
| `lots_bought` | この出口を指定した競売で、プレイヤーが落札した人だけ。売れるとすぐ移る。プレイヤーの画面は変わらない。下で説明します | 下で説明します |

`followers_sold` の出口と買い手は、最初の 1 人が舞台に上がる時点か、プレイヤーのいない所で売られる時点で選びます。それまでは MCM の変更が反映されます。指定の買い手が 12 席目に座るのもこの時点です。`followers_bought` の出口は、最初のフォロワーを落札した時点で選びます。この 2 つは `player_sold` と同じ競売では使いません。

### 段階的な出口：`lots_bought`

「競売へ行ってこの 2 人を買ってこい。買った者はこちらへ届く」というクエストのための種類です。ランダムでは選ばれず、MCM には有効と無効の切り替えしかありません。名指しの依頼で指定したときだけ使います。

プレイヤーは移動せず、暗転もしません。プレイヤーが落札した人は、拘束を解かれ、持ち物を返されて、指定のマーカーへ移ります。合図は 1 人につき 1 回届きます。

```papyrus
RegisterForModEvent("MyExitMod_LotArrived", "OnLotArrived")

Event OnLotArrived(Form lot, Int price, Bool boughtBack)
	; ここで引き止める。解放されているので、そのままだと自分の AI で帰っていく
EndEvent
```

返事はいりません。`boughtBack` は、プレイヤーがあとから受付に 1.5 倍を払ったときに True になります。依頼の競売からずっとあと、別の競売のあとにも起きるので、クエストが進んだあとに届いても困らないようにしてください。

買い戻せるのは競売場に残った人だけです。ほかの手段を用意しないなら、出口の指定と一緒に `KeepLostLots` も指定してください。

プレイヤーが払ったあとの行き先は次のとおりです。

| | 競りで落札 | 受付で買い戻し |
|---|---|---|
| 指定した出口が使える | 指定のマーカー | 指定のマーカー |
| 指定がない、または出口が消えたか無効で、元はフォロワー | フォロワーに戻る。`followers_bought` の出口があれば、そこへ移る | フォロワーに戻り、プレイヤーのそばに来る |
| 指定がない、または出口が消えたか無効で、元はフォロワーではない | プレイヤーのそばで解放 | プレイヤーのそばで解放 |

そばで解放した人は、競売場から歩いて出られないので、プレイヤーが競売場を離れたときに元の場所へ移します。

依頼主のように残っていてほしい人は、自前の NPC にしてください。合図で渡される `buyer` は、次に捕まるときに席へ戻ります。

### 1 人ごとの行き先と時期

プレイヤーを含まない競売では、売れた人は基本的にすぐ行き先へ移り、服と持ち物も戻ります。「閉会時」と書いた 2 種類だけ、見えない部屋で待ちます。

| 売れた先 | 行き先 | 時期 |
|---|---|---|
| 他の買い手。`followers_sold` の出口なし | 受付の買い戻し一覧 | **すぐ**（競りの合間にも買い戻せる） |
| 他の買い手。`each_lot` 付きの `followers_sold` の出口あり | 指定のマーカー | **すぐ** |
| 他の買い手。`each_lot` なしの `followers_sold` の出口あり | 指定のマーカー | 閉会時 |
| プレイヤー。`lots_bought` の出口を指定 | 指定のマーカー | **すぐ** |
| プレイヤー。元はフォロワー、出口なし | フォロワーに戻る | **すぐ** |
| プレイヤー。元はフォロワーではない、出口なし | プレイヤーのそばで解放 | **すぐ** |
| プレイヤー。元はフォロワー、`followers_bought` の出口あり | プレイヤーと一緒に指定のマーカーへ | 閉会時 |

`followers_bought` をすぐ動かすと、プレイヤーが競りの途中で会場を出てしまいます。`each_lot` なしの `followers_sold` は、全員分を 1 回の合図でまとめて渡すと約束しているので、そのままにします。

閉会するのは、全員が売れたときと、ゲーム内で 3 日たって残りが画面の外で売られたときです。競りの合間に檻へ人を足すと閉会は遅くなり、待っている人の待ち時間も延びます。

`each_lot` を付けると、合図は 1 人につき 1 回で、本人が渡されます。

```papyrus
RegisterForModEvent("MyExitMod_LotSold", "OnLotSold")

Event OnLotSold(Form lot, Form buyer, Int price)
	; ここで引き止める。解放されているので、そのままだと自分の AI で帰っていく
EndEvent
```

- 返事はいりません。売れた人の一覧はまだできていないので、`lot` を使ってください。
- 競売は続いています。`buyer` は入札中かもしれないので、`skyrimnet_SlaveAuction_Closed` が届くまで動かさないでください。
- 競売場の戦闘で中止になっても、すでに送り出した人は売れたままです。

### 到着時に済んでいること

全員がマーカーへ移り、解放されています。拘束、戦闘の禁止、ファストトラベルの禁止はすべて解除され、持ち物も戻っています。プレイヤーの持ち物はインベントリにあり、装備はしていません。奪ったままにしたいときは、返事をする前に奪い直してください。

プレイヤーを含まない競売から出口が受け取るフォロワーは、バニラや Nether's Follower Framework の解雇と同じ方法で解雇されています。対象は、他の買い手に売られた人と、`lots_bought` の出口ではプレイヤーが落札した人や買い戻した人です。フォロワーの枠から外れているので、プレイヤーは会話で雇い直せます。プレイヤーが売られたときに一緒に来るフォロワーは、プレイヤーのフォロワーのまま待機しています（`WaitingForPlayer` が 1）。

どちらの場合も、プレイヤーの元へ戻すときは次の合図を送ってください。本体がフォロワーのクエストを通して雇い直すので、バニラでも NFF でも動きます。

```papyrus
Int handle = ModEvent.Create("skyrimnet_SlaveAuction_ReturnFollower")
ModEvent.PushForm(handle, follower)
ModEvent.Send(handle)
```

フォロワーの所属を自分で付けないでください。解雇された人に付けると、ついて来ないフォロワーになります。フォロワーを 1 人しか持てないバニラでは、その間にプレイヤーが別の人を雇っていれば、そちらが残ります。戻した人は解雇されたままで、プレイヤーが雇い直せます。

先に `StorageUtil.GetIntValue(follower, "skyrimnet_SlaveAuction_NotFollower")` を確認してください。1 なら、MOD に名指しされただけで、プレイヤーについていたことのない人です。フォロワーにせず解放してください。出口が独自のセルで、ナビメッシュが外の世界につながっていないときは、そこから歩いて帰れません。鉱山のように、その人に `MoveToPackageLocation()` を呼んでください。

### 合図

```papyrus
RegisterForModEvent("MyExitMod_Start", "OnExitStart")

Event OnExitStart(Form buyer, Int price, String reason)
	; 奪い直し、買い手の移動など、必要な準備をする
	SendModEvent("skyrimnet_SlaveAuction_ExitAck")   ; これで暗転が解ける
EndEvent
```

- `player_sold` と `followers_bought` は、返事を最大 15 秒待ちます。返事がなければ暗転を解き、通知を出します。他の出口は試しません。
- `followers_sold` は返事が不要です。
- `buyer` は競売 MOD の NPC です。自分の場所へ移せます。次に捕まるときに席へ戻るので、いなくなっている場合に備えてください。

### 読める一覧とイベント

どれも次の捕獲まで残り、その捕獲を受け付けた時点で空になります。

```papyrus
Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_Captives")
Actor captive = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_Captives", 0) as Actor
```

| 一覧 | 内容 |
|---|---|
| `skyrimnet_SlaveAuction_Captives` | 捕まった全員。プレイヤーも含む |
| `skyrimnet_SlaveAuction_SoldCaptives` | 他の買い手が落札した人 |
| `skyrimnet_SlaveAuction_BoughtCaptives` | プレイヤーが落札した人 |

最後の 2 つは閉会時にできます。

売れるたびに、イベントも送られます。

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnSold")

Event OnSold(Form lot, Form buyer, Int price)
EndEvent
```

## 追加 MOD：借用書台帳

インストーラーで選べる独立した MOD で、どの MOD からでも NPC に借金を負わせられます。台帳のプラグインを名指しする必要はなく、イベントを送るだけです。

```papyrus
; 借金を足す。貸し手は名前で渡し、AI とほかの MOD のために記録される
Int handle = ModEvent.Create("IOULedger_AddDebt")
ModEvent.PushForm(handle, npc)
ModEvent.PushInt(handle, 10000)
ModEvent.PushString(handle, "Mine Overseer")
ModEvent.Send(handle)

; 一部を返す。0 以下なら全額を帳消しにする
handle = ModEvent.Create("IOULedger_PayDebt")
ModEvent.PushForm(handle, npc)
ModEvent.PushInt(handle, 2500)
ModEvent.Send(handle)
```

| 知りたいこと | 読み方 |
|---|---|
| 台帳が動いているか | `StorageUtil.GetIntValue(None, "IOULedger_Running") == 1` |
| この NPC に借金があるか | 借用書を持っている。キーワード `IOULedger_Bond` の付いたアイテムで、名前は `[IOU] 借用書`（英語版は `[IOU] Debt Bond`） |
| 金額 | `StorageUtil.GetIntValue(npc, "IOULedger_Debt")` |
| 最後に記録された貸し手 | `StorageUtil.GetStringValue(npc, "IOULedger_Creditor")` |
| 借金のある全員 | `StorageUtil.FormListToArray(None, "IOULedger_Debtors")` |

- **借用書が借金そのものです。** NPC から取り上げると、ゲーム内の 1 時間以内に台帳が借金を消します。借りている人が死んだときも消えます。
- 変わるたびに `IOULedger_DebtChanged` を `(Form debtor, Int total)` で送ります。借金がなくなると total は 0 です。
- プレイヤーには借金を負わせられません。
- ジャーナルの「その他」の 1 つの目標で、最大 10 人の借りている人それぞれに地図の印を付けます。フォロワー管理 MOD と同じく、名前は出しません。11 人目からも借金は残り、枠が空くと印が付きます。
- 新しい借金と借用書の意味は AI に伝わります。

ほかのプラグインがあるときだけ出口を使わせるには、出口の定義の `requires` にそのプラグインを書きます。出口サンプル「借金を背負って解放」は、こうして台帳を必須にしています。

## 注意点

- **セルのエディタ ID に「_」を入れないでください。** 場所の名前がセーブのファイル名に入り、ロード画面にセーブが出なくなります。
- **スクリプトの変数に長い文字列を持たせると、セーブがロードできなくなることがあります。** 大きなファイルを文字列に読み込まないでください。
- **ゲーム開始時から動くクエストに会話を付けるときは、`SEQ/<プラグイン名>.seq` が必要です。** ないと選択肢が出ません。スクリプトは動くので気づきにくいです。
- **会話の返答には何か文字を入れてください。** 空だと選択肢が出ないことがあります。`...` で十分です。
- **プレイヤーの選択を AI に実行させないでください。** SkyrimNet のバンドルの `dialogue_actions` ファイルで、クエストとフラグメントのスクリプトを `blacklist` に入れます。鉱山のサンプルに例があります。
- **ロードドアとエイリアスに入れた参照は、古いセーブでは位置が固定されます。** あとでプラグインで動かしても、そのセーブには反映されません。
- **他の MOD の値をプラグインに入れないでください。** バニラのレコードを上書きするときは、ロードオーダーではなく `Skyrim.esm` からコピーしてください。
- **同じ起動中にセーブを何度もロードすると、MCM のスクリプトが初期化されないまま SkyUI に使われることがあります。** そこで Papyrus のエラーが出ると、記録の途中でゲームが落ちることがあります。サンプルの MCM スクリプトの `MakeSureStarted` を見てください。

## 互換性

ここに書いたイベント名、項目、引数は、`api_version` 1 の間は変えません。変更が必要なときは番号を上げ、古い定義は MCM に「非対応」と表示します。競売 MOD の古い版では、`lots_bought` の出口は読み込めない定義として表示されます。
