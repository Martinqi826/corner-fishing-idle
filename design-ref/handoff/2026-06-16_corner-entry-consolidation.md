# Handoff · 主界面入口收敛(撤独立圆按钮 → 全走 HUD)

**日期** 2026-06-16  
**来源** 设计稿 `ui_kits/corner_fishing/`(HTML/React 版 UI,设计 source of truth)  
**目标工程** 本机 Godot 项目 `fish-idle/`(`main.gd` / `ui_panels.gd`)  
**给谁** 本机 Claude Code(直接照此在 GDScript 落地)

---

## 1. 设计决定(已在 HTML 定稿)

主界面右下角**不再放任何独立按钮**。所有入口收进常驻 HUD:

| 入口(HUD 元素) | 打开 |
|---|---|
| 金币栏(coins ledger) | 多功能面板,默认 **背包页** |
| 钓点·时段签(spot chip) | 面板 **钓点页** |
| 订单签(order chip) | 面板 **订单页** |

面板内页签覆盖:**背包 / 图鉴 / 订单 / 钓点 / 设置(/装备)**。  
理由:升级、设置、图鉴等早已并进面板页签,独立按钮与"点金币开面板"完全重复。

---

## 2. 现状核对(我读了你的代码,别凭记忆)

- 游戏**已经只剩一个**右下角按钮(鱼篓/`catch`),两套构建路径:
  - `main.gd::_build_spot_buttons()`(约 724 行)— 干净底图用 `TextureButton` + 图标,循环只有 `for k in ["catch"]`。
  - `main.gd::_build_round_buttons()`(约 771 行)— 程序化回退,`var defs := [["篓", "catch"]]`。
  - 两处注释都写明"升级/设置已并入鱼篓面板页签"。**所以游戏比 HTML 还超前一步,只是还留着最后这个鱼篓按钮。**
- **关键缺口**:`coins_label`(`main.gd:8` = `$HUD/Root/Coins`)目前只是 `Label`,只在 `_update_hud()`(531 行)写文字,**没有任何点击逻辑**。HTML 里的"点金币开面板"在游戏里**尚未实现**。
- 已有可点 HUD 元素:`spot_chip`(`_build_spot_chip` 555 行 → 开 catch 面板 tab 5)、`order_chip`(`_build_order_chip` 585 行 → tab 2)。它们是 `Button`,可作为加点击的参考写法。
- 面板开关:`_toggle_panel(kind)`(801)、`_open_panel`(937,薄壳 → `UIPanels.open_panel`)、`_close_panel`(941)。`_catch_tab` 控制默认页签(809 行,`0=鱼篓`)。

---

## 3. 实施步骤(GDScript)

> 顺序很重要:**先加金币栏入口,再撤按钮**。否则撤完会没有任何开背包页的入口。

### 步骤 A — 给金币栏加点击入口(前置,必做)

`coins_label` 是 Label,需让它可点并接管点击:

```gdscript
# _ready() 里,coins_label 定位之后(约 159 行附近)追加:
coins_label.mouse_filter = Control.MOUSE_FILTER_STOP
coins_label.gui_input.connect(func(e: InputEvent) -> void:
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        _catch_tab = 0          # 默认背包页
        _toggle_panel("catch")
)
```

⚠️ **透明窗陷阱**:这是逐像素透明 + 鼠标穿透窗口(见 `_update_passthrough()` 约 246 行)。金币栏变可点后,要确认它的矩形已包含进可交互区域,否则点击会**穿透到桌面**。请检查 `_update_passthrough()` 收集交互 rect 的逻辑里有没有带上 `coins_label`(spot/order 签是怎么进去的,照同样方式处理)。

### 步骤 B — 撤掉最后的独立按钮

两条构建路径都要清空(保持可回退,建议用空列表而非删函数):

```gdscript
# _build_spot_buttons():
for k in []:            # was ["catch"] —— 入口已收进金币栏,主界面不再放独立按钮

# _build_round_buttons():
var defs := []          # was [["篓", "catch"]]
```

> 备选(更保守):若产品希望保留鱼篓按钮作为冗余入口,则**只做步骤 A**,B 跳过。两者都满足"点金币能开面板";是否撤按钮请产品拍板。我的 HTML 取的是**全撤**。

### 步骤 C — 收尾

- `ui_layout.json` 里的 `buttons.catch` 坐标撤按钮后不再被用,可保留(无副作用)。
- 图标 `assets/art/ui/ui_button_fish|rod|coin.png` 变为未引用素材,保留即可,勿删。
- `_apply_hud_legibility()`(631 行)已对 `[coins_label, spot_chip, order_chip]` 统一描边,金币栏可读性无需额外处理。

---

## 4. 验收标准

- [ ] 主界面右下角**无任何**独立圆/图标按钮。
- [ ] **点金币栏** → 弹出多功能面板,默认停在**背包页**。
- [ ] 点钓点签 → 钓点页;点订单签 → 订单页。
- [ ] 面板内页签可达:背包 / 图鉴 / 订单 / 钓点 / 设置(/装备)。
- [ ] **透明窗**:金币栏区域可点击(不穿透到桌面);场景空白处仍可**拖动 + 穿透**。
- [ ] `godot --headless -s tools/validate_game.gd` 全过。
- [ ] `godot --path . -s tools/dev_screenshot.gd` 截图确认右下角干净、面板能开。

---

## 5. 反向同步

落地后请把最新 `main.gd`(或 dev_screenshot 截图)发回,我会据此校准 HTML 设计稿,避免两边再次漂移(这次就是 HTML 落后于游戏一个版本造成的)。
