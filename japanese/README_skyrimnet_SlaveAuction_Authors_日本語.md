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
| `no_captives` | フォロワーだけを指定したが、近くにいない |

- 競売 MOD が入っていなければ、返事は来ません。いつまでも待たないでください。
- 競売 MOD は全員の戦闘を止め、ダウン中の人を回復させます。死亡中の人は戻さず、子供は対象外です。
- 他の MOD のシーン中ではないかなど、呼んでよい状況かどうかは入口 MOD が確かめてください。
- それまでフォロワーを死なせたくなければ、Essential を付けた任意のエイリアスに入れます。入れている間だけ効きます。

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
| `for` | | `player_sold`（省略時）、`followers_sold`、`followers_bought` |
| `event` | | 到着後に送るイベント。移動だけの出口では書かない |
| `weight` | | 同じ種類の中で選ばれる確率の比率。省略時は 10。0 以下は候補から外す |
| `buyer_name` | | 名前を付けた買い手が席に座り、できる限り落札する |
| `buyer_role` | | その買い手の役割。AI に渡す |
| `buyer_female` | | 0 は男性、1 は女性 |

読み込めない定義は、理由と一緒に MCM に出ます。

### 3 つの種類

| 種類 | 移動する人 | 出口がないとき |
|---|---|---|
| `player_sold` | プレイヤーとフォロワー全員。返事をするまで暗転したまま | 解放戦線の結末 |
| `followers_sold` | 他の買い手が落札したフォロワーだけ。プレイヤーには何も見えない。**取り戻す手段を用意してください** | 競売場で待ち、受付で買い戻せる |
| `followers_bought` | プレイヤーと、プレイヤーが落札したフォロワー。返事をするまで暗転したまま | その場で普通のフォロワーに戻る |

`followers_sold` の出口と買い手は捕まった時点で、`followers_bought` の出口は閉会の時点で選びます。この 2 つは `player_sold` と同じ競売では使いません。

### 到着時に済んでいること

全員がマーカーへ移り、解放されています。拘束、戦闘の禁止、ファストトラベルの禁止、AI アクションのブロックはすべて解除され、持ち物も戻っています。プレイヤーの持ち物はインベントリにあり、装備はしていません。奪ったままにしたいときは、返事をする前に奪い直してください。

他の買い手に売られたフォロワーはパーティーから外れていて、`WaitingForPlayer` が 1 です。フォロワー管理 MOD のワープで戻らないようにするためです。プレイヤーの元へ戻すには、次のようにします。

```papyrus
follower.SetActorValue("WaitingForPlayer", 0.0)
follower.AddToFaction(Game.GetForm(0x05C84E) as Faction)   ; CurrentFollowerFaction
follower.SetPlayerTeammate(True)
```

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

どれも次に捕まるまで残ります。

```papyrus
Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_Captives")
Actor captive = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_Captives", 0) as Actor
```

| 一覧 | 内容 |
|---|---|
| `skyrimnet_SlaveAuction_Captives` | 捕まった全員。プレイヤーも含む |
| `skyrimnet_SlaveAuction_SoldCaptives` | 他の買い手が落札したフォロワー |
| `skyrimnet_SlaveAuction_BoughtCaptives` | プレイヤーが落札したフォロワー |

売れるたびに、イベントも送られます。

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnSold")

Event OnSold(Form lot, Form buyer, Int price)
EndEvent
```

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

ここに書いたイベント名、項目、引数は、`api_version` 1 の間は変えません。変更が必要なときは番号を上げ、古い定義は MCM に「非対応」と表示します。
